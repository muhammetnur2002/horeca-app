import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from './entities/category.entity';

@Injectable()
export class CategoriesService {
    constructor(@InjectRepository(Category) private repo: Repository<Category>) {}

    findAll(establishmentId: string, departmentId?: string) {
    const where: any = { establishmentId };
    if (departmentId) where.departmentId = departmentId;
    return this.repo.find({ where });
    }

    create(establishmentId: string, name: string, departmentId: string) {
    const cat = this.repo.create({ name, departmentId, establishmentId });
    return this.repo.save(cat);
    }
}