import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Establishment } from './entities/establishment.entity';

@Module({
    imports: [TypeOrmModule.forFeature([Establishment])],
    exports: [TypeOrmModule],
})
export class EstablishmentsModule {}