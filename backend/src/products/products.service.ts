import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { Product } from './entities/product.entity';
import { CreateProductDto } from './dto/create-product.dto';

@Injectable()
export class ProductsService {
    constructor(@InjectRepository(Product) private repo: Repository<Product>) {}

    findAll(establishmentId: string, filters: any) {
    const where: any = { establishmentId };
    if (filters.categoryId) where.categoryId = filters.categoryId;
    if (filters.favorite) where.isFavorite = true;
    if (filters.search) where.name = ILike(`%${filters.search}%`);
    return this.repo.find({ where });
    }

    create(establishmentId: string, dto: CreateProductDto) {
    const product = this.repo.create({ ...dto, establishmentId });
    return this.repo.save(product);
    }

    bulkCreate(establishmentId: string, names: string[]) {
    const products = names.map(name => ({ name, unit: 'шт', establishmentId }));
    return this.repo.save(products);
    }
}