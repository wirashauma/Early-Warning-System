import { SensorConnectivity } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsISO8601,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  Max,
} from 'class-validator';

/**
 * IngestPayload DTO for IoT sensor data ingestion
 * 
 * Validation Rules:
 * - At least one sensor reading (waterLevel, rainfall, or flowRate) must be provided
 * - All numeric values must be non-negative
 * - batteryLevel must be 0-100%
 * - connectivity must be one of: ONLINE, OFFLINE, MAINTENANCE
 * - recordedAt must be valid ISO 8601 timestamp
 * 
 * Service-level validation handles "at least one reading" requirement
 */
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
  @Transform(({ value }) => {
    if (value === null || value === undefined || value === '') {
      return value;
    }

    return Number(value);
  })
  @Type(() => Number)
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'waterLevel must be a valid number' })
  @Min(0, { message: 'waterLevel must be >= 0' })
  waterLevel?: number;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === null || value === undefined || value === '') {
      return value;
    }

    return Number(value);
  })
  @Type(() => Number)
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'rainfall must be a valid number' })
  @Min(0, { message: 'rainfall must be >= 0' })
  rainfall?: number;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === null || value === undefined || value === '') {
      return value;
    }

    return Number(value);
  })
  @Type(() => Number)
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'flowRate must be a valid number' })
  @Min(0, { message: 'flowRate must be >= 0' })
  flowRate?: number;

  @IsOptional()
  @IsISO8601({ strict: true }, { message: 'recordedAt must be valid ISO 8601 timestamp' })
  recordedAt?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === null || value === undefined || value === '') {
      return value;
    }

    return Number(value);
  })
  @Type(() => Number)
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'batteryLevel must be a valid number' })
  @Min(0, { message: 'batteryLevel must be >= 0' })
  @Max(100, { message: 'batteryLevel must be <= 100' })
  batteryLevel?: number;

  @IsOptional()
  @IsEnum(SensorConnectivity, { message: 'connectivity must be one of: ONLINE, OFFLINE, MAINTENANCE' })
  connectivity?: SensorConnectivity;
}
