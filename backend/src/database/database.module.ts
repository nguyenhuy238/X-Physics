import { Global, Module } from '@nestjs/common';

import { DatabaseRepository } from './database.repository';
import { databaseProvider } from './database.provider';

@Global()
@Module({
  providers: [databaseProvider, DatabaseRepository],
  exports: [databaseProvider, DatabaseRepository],
})
export class DatabaseModule {}
