import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('products')
@UseGuards(EstablishmentGuard)
export class ProductsController {
    constructor(private readonly productsService: ProductsService) {}

    @Get()
    findAll(
    @CurrentUser('establishmentId') establishmentId: string,
    @Query('categoryId') categoryId?: string,
    @Query('search') search?: string,
    @Query('favorite') favorite?: boolean,
    ) {
    return this.productsService.findAll(establishmentId, { categoryId, search, favorite });
    }

    @Post()
    create(@Body() dto: CreateProductDto, @CurrentUser('establishmentId') establishmentId: string) {
    return this.productsService.create(establishmentId, dto);
    }

    @Post('bulk')
    bulkCreate(@Body() bulkDto: { names: string[] }, @CurrentUser('establishmentId') establishmentId: string) {
    return this.productsService.bulkCreate(establishmentId, bulkDto.names);
    }
}