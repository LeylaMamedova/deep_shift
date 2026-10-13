FROM node:18-slim
WORKDIR /app
COPY . .
EXPOSE 5177
CMD ["node", "server/index.js"]
