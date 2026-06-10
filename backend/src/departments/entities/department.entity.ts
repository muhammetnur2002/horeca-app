import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Establishment } from '../../establishments/entities/establishment.entity';

@Entity('departments')
export class Department {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @Column({ default: 0 })
    sortOrder: number;

    @ManyToOne(() => Establishment, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'establishmentId' })
    establishment: Establishment;

    @Column()
    establishmentId: string;
}