import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';

import { DATABASE_POOL } from './database.constants';

export const databaseProvider = {
  provide: DATABASE_POOL,
  inject: [ConfigService],
  useFactory: (configService: ConfigService) => {
    const connectionString = configService.get<string>('DATABASE_URL');
    if (!connectionString) {
      throw new Error('DATABASE_URL is required for backend database access');
    }
    return new Pool({ connectionString });
  },
};
