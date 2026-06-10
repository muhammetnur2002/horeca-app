import { IsString, IsEnum, IsOptional, IsUUID } from 'class-validator';

export class CreateProductDto {
    @IsString()
    name: string;

    @IsEnum(['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'])
    unit: string;

    @IsUUID()
    @IsOptional()
    categoryId?: string;
}