import { Injectable, NotFoundException } from '@nestjs/common';
import { EmergencyCategory } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export class UpsertContactDto {
  name: string;
  phone: string;
  category: EmergencyCategory;
  isActive?: boolean;
}

@Injectable()
export class EmergencyContactsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.emergencyContact.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        phone: true,
        category: true,
        isActive: true,
      },
    });
  }

  async findAllAdmin() {
    return this.prisma.emergencyContact.findMany({
      orderBy: [{ isActive: 'desc' }, { category: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        name: true,
        phone: true,
        category: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async create(dto: UpsertContactDto) {
    return this.prisma.emergencyContact.create({
      data: {
        name: dto.name.trim(),
        phone: dto.phone.trim(),
        category: dto.category,
        isActive: dto.isActive ?? true,
      },
      select: {
        id: true,
        name: true,
        phone: true,
        category: true,
        isActive: true,
        createdAt: true,
      },
    });
  }

  async update(id: string, dto: Partial<UpsertContactDto>) {
    const existing = await this.prisma.emergencyContact.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Kontak darurat dengan id ${id} tidak ditemukan.`);
    }

    return this.prisma.emergencyContact.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name.trim() }),
        ...(dto.phone !== undefined && { phone: dto.phone.trim() }),
        ...(dto.category !== undefined && { category: dto.category }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
      select: {
        id: true,
        name: true,
        phone: true,
        category: true,
        isActive: true,
        updatedAt: true,
      },
    });
  }

  async remove(id: string) {
    const existing = await this.prisma.emergencyContact.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Kontak darurat dengan id ${id} tidak ditemukan.`);
    }

    await this.prisma.emergencyContact.delete({ where: { id } });
    return { deleted: true, id };
  }
}
