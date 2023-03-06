function combs = mycombs(x,y)

nx=numel(x);
ny=numel(y);

combs=zeros(nx*ny,2);
for ix=1:nx
    for iy=1:ny
        combs((ix-1)*ny+iy,:)=[x(ix),y(iy)];
    end
end
end