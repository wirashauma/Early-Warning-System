# Gunakan image Node.js yang ringan
FROM node:22-alpine

# Set direktori kerja di dalam container
WORKDIR /app

# Salin file package.json dan package-lock.json
COPY package*.json ./

# Salin folder prisma untuk generate client
COPY prisma ./prisma/

# Install semua dependensi
RUN npm install

# Instal paksa library yang hilang
RUN npm install @nestjs/config joi

# Generate Prisma Client (Wajib untuk database Supabase)
RUN npx prisma generate

# Salin seluruh sisa kode backend
COPY . .

# Build aplikasi NestJS/Node.js
RUN npm run build

# Atur environment ke production dan port ke 7860 (Wajib untuk Hugging Face)
ENV NODE_ENV=production
ENV PORT=7860

# Buka port 7860
EXPOSE 7860

# Jalankan server
CMD ["sh", "-c", "node dist/main.js || node dist/src/main.js || node dist/main.cjs"]