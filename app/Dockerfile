FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./* && \
    apk add --no-cache git && \
    git clone https://github.com/Hextris/hextris.git . && \
    apk del git
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
