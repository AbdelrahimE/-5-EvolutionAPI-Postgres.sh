#!/bin/bash

# ✅ التحقق من تشغيل السكربت بصلاحيات Root
if [[ $EUID -ne 0 ]]; then
   echo "❌ يجب تشغيل هذا السكربت بصلاحيات Root"
   exit 1
fi

echo "🚀 تحديث قائمة الحزم..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ✅ تثبيت المتطلبات الأساسية
echo "🔧 تثبيت الأدوات الأساسية..."
sudo apt-get install -y git zip unzip curl wget

# ✅ استنساخ مستودع Evolution API
echo "📥 استنساخ Evolution API..."
git clone https://github.com/EvolutionAPI/evolution-api.git
cd evolution-api

# ✅ تثبيت Node.js و npm عبر NVM
echo "📦 تثبيت Node.js و npm باستخدام NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install node
nvm use node
nvm alias default node

# ✅ تثبيت تبعيات المشروع
echo "📦 تثبيت حزم NPM..."
npm install

# ✅ تعديل ملف `.env` لاستخدام PostgreSQL
echo "📝 تعديل ملف .env لاستخدام PostgreSQL..."
cp src/dev-env.yml src/env.yml

# 🔹 طلب إدخال النطاق الفرعي
read -p "🌐 أدخل النطاق الفرعي الخاص بك (مثال: api.example.com): " sub_domain
sed -i "s|SUBDOMAIN=.*|SUBDOMAIN=$sub_domain|" src/env.yml

# 🔹 تحديث `DATABASE_URL` لاستخدام PostgreSQL
POSTGRES_URL="postgresql://api_user:ApiPassw0rd!2024@localhost:5432/evolution_api"
sed -i "s|DATABASE_URL=.*|DATABASE_URL=\"$POSTGRES_URL\"|" src/env.yml

# ✅ التأكد من أن `schema.prisma` يستخدم PostgreSQL
echo "🛠️ تحديث Prisma لاستخدام PostgreSQL..."
cat > prisma/schema.prisma <<EOF
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
EOF

# ✅ إنشاء جداول قاعدة البيانات عبر Prisma
echo "📜 تشغيل Prisma migrations..."
npx prisma generate
npx prisma migrate dev --name init

# ✅ بناء التطبيق
echo "⚙️ بناء التطبيق..."
npm run build

# ✅ تشغيل التطبيق باستخدام PM2
echo "🚀 تشغيل التطبيق باستخدام PM2..."
npm install -g pm2
pm2 start npm --name evolution-api -- run start:prod
pm2 save
pm2 startup

echo "✅ تم التثبيت بنجاح! 🎉 يمكنك الآن الوصول إلى API عبر: https://$sub_domain"