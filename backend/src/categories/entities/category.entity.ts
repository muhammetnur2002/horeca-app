import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Department } from '../../departments/entities/department.entity';
import { Establishment } from '../../establishments/entities/establishment.entity';

@Entity('categories')
export class Category {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @ManyToOne(() => Department, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'departmentId' })
    department: Department;

    @Column()
    departmentId: string;

    @ManyToOne(() => Establishment, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'establishmentId' })
    establishment: Establishment;

    @Column()
    establishmentId: string;
}