import { IsArray, IsObject, IsString } from 'class-validator';

export class SimulationDto {
  @IsString()
  lessonId!: string;

  @IsString()
  title!: string;

  @IsString()
  formula!: string;

  @IsString()
  expression!: string;

  @IsArray()
  variables!: unknown[];

  @IsObject()
  result!: Record<string, unknown>;
}
