    n=2;
    A=[4 2 1;2 3 0;1 0 1];
    I=eye(3);
    Y=((1/5 -1/5 4/5);1);
    for k=1:10 % number of iteration steps
        x=Y(1:n);
        L=Y(n+1);
        J=[A-L*I,-x;
           2*x',0];
        V=[A*x-L*x;
          x'*x-1];
%        Y=Y-inv(J)*V;
        Y=Y-J\V;
    end;
    x=Y(1:n),% approx. of eigenvector
    L=Y(n+1),% approx. of eigenvalue
    [P,D]=eig(A), % comparison with "true" eigenelements
