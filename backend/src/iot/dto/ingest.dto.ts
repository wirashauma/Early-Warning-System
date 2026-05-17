import { SensorConnectivity } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsISO8601,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class IngestPayload {
  @IsOptional()
  @IsString()
  sensorId?: string;

  @IsOptional()
  @IsString()
  waterSensorId?: string;

  @IsOptional()
  @IsString()
  rainSensorId?: string;

  @IsOptional()
  @IsString()
  flowSensorId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  waterLevel?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  rainfall?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  flowRate?: number;

  @IsOptional()
  @IsISO8601()
  recordedAt?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  batteryLevel?: number;

  @IsOptional()
  @IsEnum(SensorConnectivity)
  connectivity?: SensorConnectivity;
}
