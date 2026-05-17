import { Module } from '@nestjs/common';
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
import { UsersModule } from './users/users.module';
import { WaterLevelsModule } from './water-levels/water-levels.module';
import { IotModule } from './iot/iot.module';

@Module({
  imports: [
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
  ],
  controllers: [AppController, HealthController],
  providers: [AppService],
})
export class AppModule {}
