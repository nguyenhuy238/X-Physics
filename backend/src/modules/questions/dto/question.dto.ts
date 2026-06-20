import { IsArray, IsInt, IsString, Min } from 'class-validator';

export class QuestionDto {
  @IsString()
  lessonId!: string;

  @IsString()
  question!: string;

  @IsArray()
  options!: string[];

  @IsInt()
  @Min(0)
  correctOption!: number;

  @IsString()
  explanation!: string;
}
