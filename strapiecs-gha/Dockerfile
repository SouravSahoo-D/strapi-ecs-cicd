FROM node:20-alpine
WORKDIR /app

RUN apk add --no-cache git

COPY package*.json ./

RUN npm ci

COPY . .
RUN npm install
RUN mkdir -p /app/public/uploads
CMD ["npm", "run", "develop"]