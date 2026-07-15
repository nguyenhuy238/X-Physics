import {
  ArrayNotEmpty,
  IsArray,
  IsInt,
  IsString,
  Max,
  Min,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";

class QuizAnswerDto {
  @IsString()
  questionId!: string;

  @IsInt()
  @Min(0)
  selectedOption!: number;
}

export class SubmitQuizDto {
  @IsString()
  lessonId!: string;

  @IsInt()
  @Min(0)
  @Max(3600)
  durationSeconds!: number;

  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => QuizAnswerDto)
  answers!: QuizAnswerDto[];
}
