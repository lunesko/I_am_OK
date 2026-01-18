import React, { useState } from 'react';
import { Heart, Users, Settings, Clock, Send } from 'lucide-react';

const YaOkApp = () => {
  const [view, setView] = useState('main'); // main, family, settings
  const [lastCheckin, setLastCheckin] = useState(null);
  const [status, setStatus] = useState('ok');
  const [showStatusMenu, setShowStatusMenu] = useState(false);

  const statuses = [
    { id: 'ok', emoji: '💚', text: 'Я ОК', color: 'bg-green-500' },
    { id: 'busy', emoji: '💛', text: 'Все нормально, зайнятий', color: 'bg-yellow-500' },
    { id: 'later', emoji: '💙', text: 'Зателефоную пізніше', color: 'bg-blue-500' },
    { id: 'hug', emoji: '🤍', text: 'Обійми', color: 'bg-gray-300' }
  ];

  const family = [
    { name: 'Мама', lastSeen: '2 год тому', status: 'seen' },
    { name: 'Оля', lastSeen: '1 год тому', status: 'seen' },
    { name: 'Сашко', lastSeen: 'Ще не бачив', status: 'pending' }
  ];

  const handleCheckin = () => {
    const now = new Date();
    setLastCheckin(now);
    setTimeout(() => setLastCheckin(null), 3000);
  };

  const currentStatus = statuses.find(s => s.id === status);

  // Main Screen
  if (view === 'main') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white flex flex-col">
        {/* Header */}
        <div className="p-4 flex justify-between items-center">
          <div className="text-2xl font-bold">Я ОК</div>
          <div className="flex gap-3">
            <button 
              onClick={() => setView('family')}
              className="p-2 hover:bg-gray-700 rounded-lg transition"
            >
              <Users size={24} />
            </button>
            <button 
              onClick={() => setView('settings')}
              className="p-2 hover:bg-gray-700 rounded-lg transition"
            >
              <Settings size={24} />
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 flex flex-col items-center justify-center px-6 pb-20">
          {lastCheckin ? (
            <div className="text-center space-y-6 animate-fade-in">
              <div className="text-6xl">✓</div>
              <div className="text-2xl font-medium">Відправлено</div>
              <div className="text-gray-400 space-y-1">
                {family.map((member, i) => (
                  <div key={i}>{member.name} — побачив</div>
                ))}
              </div>
            </div>
          ) : (
            <div className="w-full max-w-sm space-y-8">
              {/* Status Selector */}
              <div className="relative">
                <button
                  onClick={() => setShowStatusMenu(!showStatusMenu)}
                  className="w-full bg-gray-800 rounded-2xl p-4 flex items-center justify-between hover:bg-gray-750 transition"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-3xl">{currentStatus.emoji}</span>
                    <span className="text-lg">{currentStatus.text}</span>
                  </div>
                  <span className="text-gray-500">▼</span>
                </button>
                
                {showStatusMenu && (
                  <div className="absolute top-full left-0 right-0 mt-2 bg-gray-800 rounded-2xl overflow-hidden shadow-xl z-10">
                    {statuses.map(s => (
                      <button
                        key={s.id}
                        onClick={() => {
                          setStatus(s.id);
                          setShowStatusMenu(false);
                        }}
                        className="w-full p-4 flex items-center gap-3 hover:bg-gray-700 transition"
                      >
                        <span className="text-2xl">{s.emoji}</span>
                        <span>{s.text}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Main Button */}
              <button
                onClick={handleCheckin}
                className={`w-full ${currentStatus.color} rounded-3xl py-8 text-3xl font-bold shadow-2xl hover:scale-105 active:scale-95 transition-transform`}
              >
                Відправити
              </button>

              {/* Last Checkin Info */}
              <div className="text-center text-gray-500 text-sm">
                <div className="flex items-center justify-center gap-2">
                  <Clock size={16} />
                  <span>Останній раз: Сьогодні, 09:15</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Bottom Info */}
        <div className="p-6 text-center text-gray-600 text-sm border-t border-gray-800">
          <div className="mb-2">⚠️ Не використовуй біля позицій</div>
          <div>Вимкни геолокацію в налаштуваннях телефону</div>
        </div>
      </div>
    );
  }

  // Family Screen
  if (view === 'family') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
        <div className="p-4 flex items-center gap-4 border-b border-gray-800">
          <button 
            onClick={() => setView('main')}
            className="text-2xl"
          >
            ←
          </button>
          <div className="text-xl font-bold">Мої люди</div>
        </div>

        <div className="p-4 space-y-3">
          {family.map((member, i) => (
            <div key={i} className="bg-gray-800 rounded-2xl p-4 flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-blue-500 rounded-full flex items-center justify-center text-xl">
                  {member.name[0]}
                </div>
                <div>
                  <div className="font-medium">{member.name}</div>
                  <div className="text-sm text-gray-400">{member.lastSeen}</div>
                </div>
              </div>
              {member.status === 'seen' && (
                <span className="text-green-500">✓✓</span>
              )}
            </div>
          ))}

          <button className="w-full bg-gray-800 rounded-2xl p-4 text-green-500 hover:bg-gray-750 transition">
            + Додати людину
          </button>
        </div>

        <div className="p-4">
          <div className="bg-gray-800 rounded-2xl p-6 space-y-4">
            <div className="flex items-center gap-3">
              <Heart className="text-blue-400" size={24} />
              <div className="font-medium">Зворотній зв'язок</div>
            </div>
            <div className="text-gray-400 text-sm">
              Твої близькі теж можуть надіслати тобі швидке повідомлення "Вдома все добре"
            </div>
            <button className="w-full bg-blue-600 rounded-xl py-3 hover:bg-blue-700 transition">
              Надіслати "Вдома все добре"
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Settings Screen
  if (view === 'settings') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
        <div className="p-4 flex items-center gap-4 border-b border-gray-800">
          <button 
            onClick={() => setView('main')}
            className="text-2xl"
          >
            ←
          </button>
          <div className="text-xl font-bold">Налаштування</div>
        </div>

        <div className="p-4 space-y-4">
          <div className="bg-gray-800 rounded-2xl p-4">
            <div className="font-medium mb-2">Нагадувати мені</div>
            <select className="w-full bg-gray-700 rounded-xl p-3">
              <option>Кожен день о 09:00</option>
              <option>Кожен день о 18:00</option>
              <option>Кожні 12 годин</option>
              <option>Не нагадувати</option>
            </select>
          </div>

          <div className="bg-gray-800 rounded-2xl p-4">
            <div className="font-medium mb-2">Попередити близьких через</div>
            <select className="w-full bg-gray-700 rounded-xl p-3">
              <option>2 дні без зв'язку</option>
              <option>3 дні без зв'язку</option>
              <option>5 днів без зв'язку</option>
              <option>Тиждень без зв'язку</option>
            </select>
          </div>

          <div className="bg-gray-800 rounded-2xl p-4 flex items-center justify-between">
            <div>
              <div className="font-medium">Тихий режим</div>
              <div className="text-sm text-gray-400">Без звукових сповіщень вночі</div>
            </div>
            <input type="checkbox" className="w-12 h-6" defaultChecked />
          </div>

          <div className="bg-gray-800 rounded-2xl p-4 flex items-center justify-between">
            <div>
              <div className="font-medium">Оффлайн режим</div>
              <div className="text-sm text-gray-400">Відправка при появі мережі</div>
            </div>
            <input type="checkbox" className="w-12 h-6" defaultChecked />
          </div>

          <div className="bg-gradient-to-r from-blue-600 to-yellow-500 rounded-2xl p-6 text-center space-y-3">
            <div className="text-xl font-bold">Підтримати проєкт</div>
            <div className="text-sm opacity-90">
              Я ОК — безкоштовний для військових та їх родин
            </div>
            <button className="w-full bg-white text-gray-900 rounded-xl py-3 font-bold hover:bg-gray-100 transition">
              Задонатити на ЗСУ ❤️
            </button>
          </div>
        </div>
      </div>
    );
  }
};

export default YaOkApp;