import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import * as Joi from 'joi';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AlertsModule } from './alerts/alerts.module';
import { AuthModule } from './auth/auth.module';
import { EmergencyContactsModule } from './emergency-contacts/emergency-contacts.module';
import { HealthController } from './health/health.controller';
import { FirebaseModule } from './common/firebase/firebase.module';
import { PrismaModule } from './prisma/prisma.module';
import { RainfallModule } from './rainfall/rainfall.module';
import { FlowRateModule } from './flow-rate/flow-rate.module';
import { SensorsModule } from './sensors/sensors.module';
import { ThresholdsModule } from './thresholds/thresholds.module';
import { NotificationsController } from './notifications/notifications.controller';
import { NotificationsService } from './notifications/notifications.service';
import { UsersModule } from './users/users.module';
import { WaterLevelsModule } from './water-levels/water-levels.module';
import { IotModule } from './iot/iot.module';
import { DischargeModule } from './discharge/discharge.module';
import { ReportModule } from './reports/report.module';
import { RealtimeModule } from './realtime/realtime.module';
import { StorageModule } from './common/storage/storage.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
      validationSchema: Joi.object({
        NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
        PORT: Joi.number().default(4101),
        DATABASE_URL: Joi.string().required(),
        DIRECT_URL: Joi.string().optional(),
        JWT_SECRET: Joi.string().default('rahasia-super-kuat-ews-123'),
        FIREBASE_SERVICE_ACCOUNT_PATH: Joi.string().optional(),
        SUPABASE_URL: Joi.string().optional(),
        SUPABASE_SERVICE_ROLE_KEY: Joi.string().optional(),
        SMTP_HOST: Joi.string().optional(),
        SMTP_PORT: Joi.number().optional(),
        SMTP_USER: Joi.string().optional(),
        SMTP_PASS: Joi.string().optional(),
        SMTP_FROM: Joi.string().optional(),
        ALLOWED_ORIGINS: Joi.string().allow('').optional(),
        ALLOW_NGROK_ORIGINS: Joi.boolean().truthy('true').falsy('false').default(true),
      }),
    }),
    FirebaseModule,
    PrismaModule,
    AuthModule,
    WaterLevelsModule,
    RainfallModule,
    FlowRateModule,
    SensorsModule,
    IotModule,
    AlertsModule,
    ThresholdsModule,
    UsersModule,
    EmergencyContactsModule,
    DischargeModule,
    ReportModule,
    RealtimeModule,
    StorageModule,
  ],
  controllers: [AppController, HealthController, NotificationsController],
  providers: [
    AppService,
    NotificationsService,
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
