import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { json, urlencoded } from 'express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const isDevelopment = config.get<string>('NODE_ENV') !== 'production';
  const allowNgrokOrigins = (config.get<string>('ALLOW_NGROK_ORIGINS') ?? 'false') === 'true';

  // 1. SECURITY: Headers (Helmet)
  app.use(helmet());

  // 2. PAYLOAD LIMIT: For large base64 avatars
  app.use(json({ limit: '5mb' }));
  app.use(urlencoded({ extended: true, limit: '5mb' }));

  // 3. CORS: Hardened for Production
  const allowedOrigins = (config.get<string>('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  const defaultOrigins = [
    'http://localhost:4100',
    'http://127.0.0.1:4100',
    'http://localhost:4101',
    'https://ews-floodguard.vercel.app', // Example production URL
  ];

  const isLocalOrigin = (origin: string) => {
    try {
      const parsed = new URL(origin);
      return ['localhost', '127.0.0.1', '::1'].includes(parsed.hostname);
    } catch {
      return false;
    }
  };

  const isNgrokOrigin = (origin: string) => {
    try {
      const parsed = new URL(origin);
      return [
        'ngrok-free.app',
        'ngrok.app',
        'ngrok.io',
        'ngrok.dev',
      ].some((suffix) => parsed.hostname === suffix || parsed.hostname.endsWith(`.${suffix}`));
    } catch {
      return false;
    }
  };

  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      if (!origin) {
        callback(null, true);
        return;
      }

      const isAllowed =
        allowedOrigins.includes(origin) ||
        (isDevelopment && (isLocalOrigin(origin) || (allowNgrokOrigins && isNgrokOrigin(origin)))) ||
        (allowNgrokOrigins && isNgrokOrigin(origin)) ||
        defaultOrigins.includes(origin);

      if (isAllowed) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  });

  // 4. VALIDATION: Global Pipe for DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      errorHttpStatusCode: 422,
    }),
  );

  // 5. GLOBAL FILTERS
  app.useGlobalFilters(new GlobalExceptionFilter());

  // 6. GLOBAL CONFIG
  app.setGlobalPrefix('api');

  const port = Number(config.get<number>('PORT') ?? 4101);
  await app.listen(port, '0.0.0.0');
  
  logger.log(`EWS Backend is running on: ${await app.getUrl()}`);
  logger.log(`Allowed Origins: ${(allowedOrigins.length ? allowedOrigins : defaultOrigins).join(', ')}`);
  logger.log(`Ngrok Origins Enabled: ${allowNgrokOrigins ? 'yes' : 'no'}`);
}

void bootstrap();
