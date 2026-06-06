import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { SensorConnectivity, SensorType } from "@prisma/client";

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();

    const dataToUpdate: Partial<{
      sensorId: string;
      name: string;
      type: SensorType;
      latitude: number;
      longitude: number;
      batteryLevel: number;
      connectivity: SensorConnectivity;
      lastActiveAt: Date;
    }> = {};
    if (body.sensorId !== undefined) dataToUpdate.sensorId = body.sensorId;
    if (body.name !== undefined) dataToUpdate.name = body.name;
    
    if (body.type !== undefined) {
      const typeUpper = body.type.toUpperCase();
      if (Object.values(SensorType).includes(typeUpper as SensorType)) {
        dataToUpdate.type = typeUpper as SensorType;
      }
    }
    if (body.latitude !== undefined) dataToUpdate.latitude = Number(body.latitude);
    if (body.longitude !== undefined) dataToUpdate.longitude = Number(body.longitude);
    if (body.batteryLevel !== undefined) dataToUpdate.batteryLevel = Number(body.batteryLevel);
    
    if (body.connectivity !== undefined) {
      const connectivityUpper = body.connectivity.toUpperCase();
      if (Object.values(SensorConnectivity).includes(connectivityUpper as SensorConnectivity)) {
        dataToUpdate.connectivity = connectivityUpper as SensorConnectivity;
      }
    }

    dataToUpdate.lastActiveAt = new Date();

    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    const where = isUuid ? { id } : { sensorId: id };

    const updatedSensor = await prisma.sensor.update({
      where,
      data: dataToUpdate,
    });

    return NextResponse.json({
      success: true,
      data: updatedSensor,
    });
  } catch (error) {
    console.error("Error updating sensor via Next.js API:", error);
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : "Failed to update sensor" },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  return PATCH(request, { params });
}
