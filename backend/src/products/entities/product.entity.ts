import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Establishment } from '../../establishments/entities/establishment.entity';
import { Category } from '../../categories/entities/category.entity';

@Entity('products')
export class Product {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @Column({ type: 'enum', enum: ['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'] })
    unit: string;

    @Column({ default: false })
    isFavorite: boolean;

    @ManyToOne(() => Establishment, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'establishmentId' })
    establishment: Establishment;

    @Column()
    establishmentId: string;

    @ManyToOne(() => Category, { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'categoryId' })
    category: Category;

    @Column({ nullable: true })
    categoryId: string;
}