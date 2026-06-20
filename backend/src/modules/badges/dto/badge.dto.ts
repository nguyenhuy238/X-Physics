import { IsString } from 'class-validator';

export class BadgeDto {
  @IsString()
  name!: string;

  @IsString()
  description!: string;

  @IsString()
  ruleKey!: string;
}
