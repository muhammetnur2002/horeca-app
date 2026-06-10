import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const headerId = request.headers['x-establishment-id'];
    return headerId || 'a0081dc3-e574-493b-b3a3-a18c02cdf458';
  },
);