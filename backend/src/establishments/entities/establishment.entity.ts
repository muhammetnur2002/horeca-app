import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('establishments')
export class Establishment {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;
}