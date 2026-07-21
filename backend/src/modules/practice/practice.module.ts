import { Module } from "@nestjs/common";

import { DatabaseModule } from "../../database/database.module";
import { PracticeController } from "./practice.controller";
import { PracticeService } from "./practice.service";

@Module({
  imports: [DatabaseModule],
  controllers: [PracticeController],
  providers: [PracticeService],
  exports: [PracticeService],
})
export class PracticeModule {}
