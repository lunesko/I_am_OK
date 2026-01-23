package app.poruch.ya_ok.transport

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

class BleTransport(
    private val context: Context,
    private val onMessage: (String, String) -> Unit
) {
    private val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val adapter: BluetoothAdapter? = manager.adapter
    private var gattServer: BluetoothGattServer? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null
    private val connectedDevices = ConcurrentHashMap<String, BluetoothDevice>()
    private val clientGatt = ConcurrentHashMap<String, BluetoothGatt>()
    private val assembler = BleAssembler()
    private val handler = Handler(Looper.getMainLooper())

    fun start() {
        if (adapter == null || !adapter.isEnabled) return
        try {
            setupServer()
            startAdvertising()
            startScanning()
        } catch (e: SecurityException) {
            // Missing Bluetooth permissions - ignore silently
        }
    }

    fun stop() {
        scanner?.stopScan(scanCallback)
        advertiser?.stopAdvertising(advertiseCallback)
        gattServer?.close()
        clientGatt.values.forEach { it.close() }
        clientGatt.clear()
        connectedDevices.clear()
    }

    fun send(json: String) {
        if (connectedDevices.isEmpty()) return
        val payload = json.toByteArray(Charsets.UTF_8)
        val framed = addLengthHeader(payload)
        val chunks = framed.asList().chunked(CHUNK_SIZE).map { it.toByteArray() }

        connectedDevices.values.forEach { device ->
            val gatt = clientGatt[device.address]
            if (gatt != null) {
                writeChunks(gatt, chunks)
            } else {
                notifyChunks(device, chunks)
            }
        }
    }

    private fun setupServer() {
        gattServer = manager.openGattServer(context, serverCallback)
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val characteristic = BluetoothGattCharacteristic(
            CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        service.addCharacteristic(characteristic)
        gattServer?.addService(service)
    }

    private fun startAdvertising() {
        advertiser = adapter?.bluetoothLeAdvertiser
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .build()
        val data = AdvertiseData.Builder()
            .addServiceUuid(android.os.ParcelUuid(SERVICE_UUID))
            .setIncludeDeviceName(false)
            .build()
        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    private fun startScanning() {
        scanner = adapter?.bluetoothLeScanner
        val filters = listOf(ScanFilter.Builder().setServiceUuid(android.os.ParcelUuid(SERVICE_UUID)).build())
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        scanner?.startScan(filters, settings, scanCallback)
    }

    private val advertiseCallback = object : android.bluetooth.le.AdvertiseCallback() {}

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            if (clientGatt.containsKey(device.address)) return
            device.connectGatt(context, false, clientCallback)?.let { gatt ->
                clientGatt[device.address] = gatt
            }
        }
    }

    private val serverCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                connectedDevices[device.address] = device
            } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
                connectedDevices.remove(device.address)
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            val complete = assembler.append(device.address, value)
            if (complete != null) {
                onMessage(String(complete, Charsets.UTF_8), device.address)
            }
            if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
            }
        }
    }

    private val clientCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                gatt.discoverServices()
            } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
                clientGatt.remove(gatt.device.address)
                gatt.close()
            }
        }
    }

    private fun writeChunks(gatt: BluetoothGatt, chunks: List<ByteArray>) {
        val service = gatt.getService(SERVICE_UUID) ?: return
        val characteristic = service.getCharacteristic(CHAR_UUID) ?: return
        characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
        handler.post(object : Runnable {
            var index = 0
            override fun run() {
                if (index >= chunks.size) return
                characteristic.value = chunks[index]
                gatt.writeCharacteristic(characteristic)
                index += 1
                handler.postDelayed(this, 20)
            }
        })
    }

    private fun notifyChunks(device: BluetoothDevice, chunks: List<ByteArray>) {
        val service = gattServer?.getService(SERVICE_UUID) ?: return
        val characteristic = service.getCharacteristic(CHAR_UUID)
        handler.post(object : Runnable {
            var index = 0
            override fun run() {
                if (index >= chunks.size) return
                characteristic.value = chunks[index]
                gattServer?.notifyCharacteristicChanged(device, characteristic, false)
                index += 1
                handler.postDelayed(this, 20)
            }
        })
    }

    private fun addLengthHeader(payload: ByteArray): ByteArray {
        val header = ByteBuffer.allocate(4).putInt(payload.size).array()
        return header + payload
    }

    companion object {
        private val SERVICE_UUID = UUID.fromString("2f61cdb3-1b5f-4b2a-9a8d-3f6b9c3c1b00")
        private val CHAR_UUID = UUID.fromString("2f61cdb3-1b5f-4b2a-9a8d-3f6b9c3c1b01")
        private const val CHUNK_SIZE = 180
    }
}

private class BleAssembler {
    private data class BufferState(
        var expected: Int = -1,
        val bytes: MutableList<Byte> = mutableListOf()
    )

    private val buffers = ConcurrentHashMap<String, BufferState>()

    fun append(deviceId: String, chunk: ByteArray): ByteArray? {
        val state = buffers.getOrPut(deviceId) { BufferState() }
        var data = chunk
        if (state.expected == -1 && chunk.size >= 4) {
            val length = ByteBuffer.wrap(chunk, 0, 4).int
            state.expected = length
            data = chunk.copyOfRange(4, chunk.size)
        }
        data.forEach { state.bytes.add(it) }
        return if (state.expected != -1 && state.bytes.size >= state.expected) {
            val result = state.bytes.take(state.expected).toByteArray()
            buffers.remove(deviceId)
            result
        } else {
            null
        }
    }
}
