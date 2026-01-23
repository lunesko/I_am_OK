FROM nginx:alpine

# Support page as root index
COPY support-page.html /usr/share/nginx/html/index.html
COPY support-page.html /usr/share/nginx/html/support.html

# Legal pages
COPY privacy.html /usr/share/nginx/html/privacy.html
COPY terms.html /usr/share/nginx/html/terms.html
