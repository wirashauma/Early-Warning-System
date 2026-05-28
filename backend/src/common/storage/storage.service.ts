import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class StorageService {
  private readonly supabaseUrl: string;
  private readonly serviceRoleKey: string;

  constructor(private readonly configService: ConfigService) {
    this.supabaseUrl = this.configService.get<string>('SUPABASE_URL') || '';
    this.serviceRoleKey = this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY') || '';
  }

  async uploadAvatar(fileBuffer: Buffer, originalFilename: string, mimeType: string): Promise<string> {
    if (!this.supabaseUrl || !this.serviceRoleKey) {
      throw new InternalServerErrorException(
        '[StorageService] Missing Supabase environment variables: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set.',
      );
    }

    const fileExt = originalFilename.split('.').pop() || 'png';
    const uniqueFilename = `${Date.now()}-${Math.random().toString(36).substring(2, 15)}.${fileExt}`;
    // Supabase Object Storage Upload Endpoint: /storage/v1/object/{bucket}/{path}
    const uploadUrl = `${this.supabaseUrl}/storage/v1/object/avatars/${uniqueFilename}`;

    try {
      await axios.post(uploadUrl, fileBuffer, {
        headers: {
          'Authorization': `Bearer ${this.serviceRoleKey}`,
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
      });

      // Public URL pattern for a public bucket named "avatars"
      return `${this.supabaseUrl}/storage/v1/object/public/avatars/${uniqueFilename}`;
    } catch (error: any) {
      const errorMsg = error.response?.data?.message || error.message || 'Unknown storage upload error';
      throw new InternalServerErrorException(`Gagal mengunggah foto profil ke Supabase: ${errorMsg}`);
    }
  }
}
