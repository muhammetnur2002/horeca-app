import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EstablishmentsModule } from './establishments/establishments.module';
import { DepartmentsModule } from './departments/departments.module';
import { CategoriesModule } from './categories/categories.module';
import { ProductsModule } from './products/products.module';
import { RequestsModule } from './requests/requests.module';
import { InventoryModule } from './inventory/inventory.module';
import { SyncModule } from './sync/sync.module';
import { DocumentsModule } from './documents/documents.module';
import * as Joi from 'joi';

@Module({
    imports: [
    ConfigModule.forRoot({
        isGlobal: true,
        validationSchema: Joi.object({
        DB_HOST: Joi.string().required(),
        DB_PORT: Joi.number().default(5432),
        DB_USERNAME: Joi.string().required(),
        DB_PASSWORD: Joi.string().required(),
        DB_NAME: Joi.string().required(),
        }),
    }),
    TypeOrmModule.forRootAsync({
        imports: [ConfigModule],
        useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST'),
        port: parseInt(configService.get<string>('DB_PORT') ?? '5432', 10),
        username: configService.get<string>('DB_USERNAME'),
        password: configService.get<string>('DB_PASSWORD'),
        database: configService.get<string>('DB_NAME'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: true,
        }),
        inject: [ConfigService],
    }),
    EstablishmentsModule,
    DepartmentsModule,
    CategoriesModule,
    ProductsModule,
    RequestsModule,
    InventoryModule,
    SyncModule,
    DocumentsModule,
    ],
})
export class AppModule {}