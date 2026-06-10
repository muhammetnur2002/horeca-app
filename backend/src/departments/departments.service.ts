import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Department } from './entities/department.entity';

@Injectable()
export class DepartmentsService {
    private readonly logger = new Logger(DepartmentsService.name);

    constructor(@InjectRepository(Department) private repo: Repository<Department>) {}

    findAll(establishmentId: string) {
    return this.repo.find({ where: { establishmentId } });
    }

    async create(establishmentId: string, name: string) {
    try {
        const dept = this.repo.create({ name, establishmentId });
        return await this.repo.save(dept);
    } catch (error) {
        this.logger.error('Failed to create department', error.stack);
      throw error; // всё равно выбрасываем, чтобы клиент получил 500, но с логами
    }
    }
}