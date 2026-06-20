export class ApiResponseDto<T> {
  constructor(
    public readonly success: boolean,
    public readonly message: string,
    public readonly data?: T,
    public readonly errors?: Array<{ field?: string; message: string }>,
  ) {}

  static ok<T>(data: T, message = 'OK'): ApiResponseDto<T> {
    return new ApiResponseDto(true, message, data);
  }
}
