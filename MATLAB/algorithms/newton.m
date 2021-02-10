function [x,F,J,iter,status] = newton(funobj,x0,maxiter,printlevel,tol)
%------------------------------------------------------------------------
%  The function call
%
%     [x,F,J,iter,stauts] = newton( funobj,x0,maxiter,printlevel,tol )
%
%  aims to compute a vector x such that F(x) = 0 for a function F(x). 
%  The zero is sought by using Newton's method.
%
%  Input arguments:
%  ----------------
%    Fname      : string containing the name of an m-file that 
%                 evaluates a function F and its Jaobian. The function
%                 value and Jacobian of F must be defined in an M-file
%                 named Fname with specification [F,J] = Fname(x). 
%    x0         : initial guess at a zero of F. 
%    maxiter    : maximum number of allowed iterations.
%    printlevel : amount of printing to perform.
%                    0  no printing
%                    1  single line of output per iteration
%                 When printing is requested, the following is displayed:
%                    Iter       current iteration number
%                    Norm-F     two-norm of F at the current iterate x
%                    Norm-x     two-norm of current iterate x
%                    Norm-step  two-norm of Newton step during iteration
%    tol        : desired stoppping tolerance on the size of F(x).
%
%  Output arguments:
%  -----------------
%    x      : final iterate computed
%    F      : value of F at the final computed iterate
%    J      : value of the Jacobian of F at the final computed iterate
%    iter   : total number of iterations performed
%    status : integer indicating the reason for termination
%              0  Successful termination since norm(F(x)) <= tol
%              1  Newton step is too small to make any further progress
%              2  Maximum number of iterations was reached
%             -1  An error in the inputs was detected.
%             -2  A NaN or Inf was detected.
%             -9  New warning encountered.
%
% Author:
% ----------------
% Daniel P. Robinson
% Lehigh University
% Department of Industrial and Systems Engineering
% Bethlehem, PA, 18015, USA
%
% History:
% -----------------
% March 3, 2020:
%    - This is the original version.
% February 9, 2021:
%    - Changed to a relative stopping condition.
%    - Changed the first input parameter to be an object.
%    - Added explicit handling of some warnings in the linear system caused
%      my matrices that were (nearly) singular.
%-------------------------------------------------------------------------

% Turn off certain warnings that I will explicitely handle in the code.
warning('off','MATLAB:illConditionedMatrix');
warning('off','MATLAB:singularMatrix');

% Set dummy values for output arguments.
% Will prevent errors if termination because of bad input arguments.  
x = [];
F = [];
J = [];
iter = 0;
status = 0;

% Mark sure the correct number of arguments are passed in.
if nargin < 5
    fprintf('\n newton(ERROR):Wrong number of input arguments.\n');
    status = -1; 
    return
end

% Check to make sure that the arguments passed in make sense.
% if ~(exist(Fname, 'file') == 2)
%     str = 'Fname';
%     fprintf('newton(ERROR):no file with name %s exists on path.\n',str);
%     status = -1;
%     return   
% end
if length(x0) <= 0
    str = 'x0';
    fprintf('\n newton(ERROR):Invalid value for argument %s.\n',str);
    status = -1; 
    return
end
if maxiter < 0
    str = 'maxiter';
    fprintf('\n newton(ERROR):Invalid value for argument %s.\n',str);
    status = -1; 
    return
end
if printlevel < 0
    str = 'printlevel';
    fprintf('\n newton(ERROR):Invalid value for argument %s.\n',str);
    status = -1; 
    return
end
if tol < 0
    str = 'tol';
    fprintf('\n newton(ERROR):Invalid value for argument %s.\n',str);
    status = -1; 
    return
end

% Constant
TINY = eps^(2/3); % Determines if step is too small to make progress.

% Initialization.
x      = x0;
normx  = norm(x);
F      = funobj.grad(x);
J      = funobj.hess(x);
normF  = norm(F);
normF0 = normF;  % Save value at x0 for use in relative stopping condition.

% Print column header and value of F at initial point.
if printlevel ~= 0
  fprintf(' -----------------------------------------------------------\n');
  fprintf('                   Newton Method                            \n');
  fprintf(' -----------------------------------------------------------\n');
  fprintf('  Iter      Norm-F         Norm-x       Norm-step    Warning \n')
  fprintf(' %5g %14.7e %14.7e', iter, normF, normx );
end

% Main loop: perform Newton iterations.
while ( 1 )

  % Check for termination
  if ( normF <= tol*max(1,normF0) )
     status = 0;
     outcome = ' Relative stopping tolerance reached';
     break
  elseif ( iter >= maxiter )
     status = 2;
     outcome = ' Maximum allowed iterations reached';
     break
  end
      
  % Compute Newton step p.
  % ----------------------
  lastwarn('', '');          % Reset the lastwarn message and id.
  p = - J\F;                 % Solve the Newton linear system.
  [~, warnId] = lastwarn();  % Check for warning.
  
  % Set warning string appropriately
  if( isempty(warnId) )
      warnstring = '   -   ';
  elseif strcmp(warnId,'MATLAB:singularMatrix')
      warnstring = '  sing ';
  elseif strcmp(warnId,'MATLAB:illConditionedMatrix')
      warnstring = 'ill-cond';
  else
      status = -9;
      outcome = ' ERROR (unknown NEW warning encountered)';
      break
  end
  
  % Set norm of the Newton step.
  if sum(isnan(p)) >= 1 || sum(isinf(p)) >= 1
      status = -2;
      outcome = ' ERROR (NaN/Inf in the search direction)';
      break
  else
      normp = norm(p);
  end
  
  % Save norm of current iterate before moving updating.
  normxprev = normx;
  
  % Update the iterate and its associated values.
  iter  = iter + 1;
  x     = x + p;
  normx = norm(x);
  F     = funobj.grad(x);
  J     = funobj.hess(x);
  normF = norm(F);
  
  % Check for NaNs in F and J.
  if sum(isnan(F)) >= 1 || sum(isinf(F)) >= 1
      status = -2;
      outcome = ' ERROR (NaN when evaluating F)';
      break
  elseif sum(isnan(J(:))) >= 1 || sum(isinf(J(:))) >= 1
      status = -2;
      outcome = ' ERROR (NaN when evaluating J)';
      break
  end
  
  % Print iterate information, if needed.
  if printlevel ~= 0
    fprintf(' %14.7e  %s \n', normp, warnstring);      % End previous line. 
    fprintf(' %5g %14.7e %14.7e', iter, normF, normx); % Start next line.
  end
  
  % Terminate if Newton step was too small to make significant progress.
  if normp < (1 + normxprev)*TINY
     status = 1;
     outcome = ' Newton step is too small to make additional progress.';
     break
  end
  
end

% Print termination message, if requested.
if printlevel
  fprintf( '\n\n Result     :%s \n', outcome)
  if status == 1
    fprintf( '              ||x||    : %13.7e\n', normx)
    fprintf( '              ||step|| : %13.7e\n', normp)
  end
  fprintf( ' Iterations : %-5g\n', iter)
  fprintf( ' Final |F|  : %13.7e\n', normF );
  fprintf(' --------------------------------------------------\n');
end
  
return
