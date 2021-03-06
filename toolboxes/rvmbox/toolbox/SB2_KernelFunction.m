% KERNELFUNCTION    Compute kernel functions for the RVM model
%
%       K = KERNELFUNCTION(X1,X2,KERNEL,LENGTH)
%
% OUTPUT ARGUMENTS:
%
%       K       N1 x N2 kernel matrix.
% 
% INPUT ARGUMENTS:
%
%       X1      N1 x d data matrix
%       X2      N2 x d data matrix
%       KERNEL  Kernel type: currently one of
%               'gauss'         Gaussian
%               'laplace'       Laplacian
%               'polyN'         Polynomial of order 'N'
%               'hpolyN'        Homogeneous Polynomial of order 'N'
%               'spline'        Linear spline [Vapnik et al]
%               'cauchy'        Cauchy (heavy tailed) in distance
%               'cubic'         Cube of distance
%               'r'             Distance
%       LENGTH  Input length scale
% 
%
% This file is adapted from the SPARSEBAYES baseline implementation (V1.10)
%
%
function K = SB2_KernelFunction(X1,X2,kernel_,lengthScale)

[N1 d]		= size(X1);
[N2 d]		= size(X2);

if length(kernel_)>=4 && strcmp(kernel_(1:4),'poly')
  p		= str2double(kernel_(5:end));
  kernel_	= 'poly';
end
if length(kernel_)>=5 && strcmp(kernel_(1:5),'hpoly')
  p		= str2double(kernel_(6:end));
  kernel_	= 'hpoly';
end
eta	= 1/(2*lengthScale^2);
p = 10;

switch lower(kernel_)
  
 case 'gaussian',
  K	= exp(-eta*distSqrd(X1,X2));
  
 case 'cauchy',
  r2	= eta*distSqrd(X1,X2);
  K	= 1./(1+r2);
  
 case 'cubic',
  r2	= eta*distSqrd(X1,X2);
  K	= r2.*sqrt(r2);
  
 case 'r',
  K	= sqrt(eta)*sqrt(distSqrd(X1,X2));
  
 case 'laplace',
  K	= exp(-sqrt(eta*distSqrd(X1,X2)));
  
 case 'poly',
  eta = lengthScale;
  K	= (X1*(eta*X2)' + 1).^p;

 case 'hpoly',
  eta = lengthScale;
  K	= (eta*X1*X2').^p;

 case 'spline',
  K	= 1;
  X1	= X1/lengthScale;
  X2	= X2/lengthScale;
  for i=1:d
    XX		= X1(:,i)*X2(:,i)';
    Xx1		= X1(:,i)*ones(1,N2);
    Xx2		= ones(N1,1)*X2(:,i)';
    minXX	= min(Xx1,Xx2);
    
    K	= K .* [1 + XX + XX.*minXX-(Xx1+Xx2)/2.*(minXX.^2) + (minXX.^3)/3];
  end
  
 otherwise,
  error('Unrecognised kernel function type: %s', kernel_)
end

%%
%% Support function: squared distance
%%
function D2 = distSqrd(X,Y)
nx	= size(X,1);
ny	= size(Y,1);
D2	= sum(X.^2,2)*ones(1,ny) + ones(nx,1)*sum(Y.^2,2)' - 2*(X*Y');
