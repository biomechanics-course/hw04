% Equations of motion for simplest walking model
% Event detection for simplest walking model

function simplestwalkingstep()

xs = [0.3 -0.3 0.1 0.1; 0.25 -0.25 0.1 0.1];
animatesimpwalk2(xs, 2)

%% Put your code here to complete the model and find periodic gaits

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xdot = fsimpwalk2(t,x)
% state derivative function for a simple walker with point masses

% The following variables are available in this
% subfunction:  gamma M L g Kp

% Define constants

% Define forces: 

% State assignments
q1 = x(1); q2 = x(2); 
u1 = x(3); u2 = x(4); 

c1m2 = cos(q1 - q2); s1m2 = sin(q1 - q2); 

MM = zeros(2,2); rhs = zeros(2,1);

% Mass Matrix
MM(1,1) = M; MM(1,2) = 0; 
MM(2,1) = -c1m2; MM(2,2) = 1; 

% righthand side terms
rhs(1) = g/L*M*sin(q1 - gamma); 
rhs(2) = -Kp*(q2-q1) -s1m2*(u1*u1) - g/L*sin(q2 - gamma); 

udot = MM\rhs;
xdot = [x(3:4); udot];

end % fsimpwalk2


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [value, isterminal, direction] = eventsimpwalk2(t, x)
% returns event function for passive walking simulation

% Here is how event checking works:  
% At each integration step, ode45 checks to see if an
% event function passes through zero (in this case, we need
% the function to go through zero when the foot hits the
% ground).  It finds the value of the event function by calling
% eventswalk2, which is responsible for returning the value of the 
% event function in variable value.  isterminal should contain
% a 1 to signify that the integration should stop (otherwise it
% will keep going after value goes through zero).  Finally,
% direction should specify whether to look for event function
% going through zero with positive or negative slope, or either.

% we want to stop the simulation when theta = alpha
% or when (theta - alpha) is zero
q1 = x(1); q2 = x(2); u1 = x(3); u2 = x(4);

value = cos(q1) - cos(q2);
% here is a trick to use to ignore heel scuffing, by 
% making sure the stance leg is past vertical before
% an event causes the simulation to stop
if q1 < 0 % A criterion other than 0 angle can also improve
          % robustness, but can limit range of acceptable slopes
  isterminal = 1;  % tells ode45 to stop when event occurs
else
  isterminal = 0;  % keep going
end
direction = -1;  % tells ode45 to look for negative crossing

end % event simplest walker

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xnew = heelstrikesimpwalk2(xminus)
% calculates the new state following foot contact.
% Angular momentum is conserved about the impact point for the
% whole machine, and about the hip joint for the trailing leg.
% After conservation of angular momentum is applied, the legs
% are switched.
% State vector: qstance, qswing, qdotstance, qdotswing


sg = sin(gamma); cg = cos(gamma);

MM = zeros(2,2);
amb = zeros(2,1);

q1 = xminus(1); q2 = xminus(2); u1 = xminus(3); u2 = xminus(4);

c1 = cos(q1); c2 = cos(q2); c12 = cos(q1-q2);
s1 = sin(q1); s2 = sin(q2); s12 = sin(q1-q2);

% Angular momentum before impact:
%   amb(1) is angular momentum of whole system about heel contact
%   amb(2) is angular momentum of trailing leg about the hip

amb(1) = cos(q1-q2)*u1;

amb(2) = cos(q1-q2)^2*u1;

% Angular momentum after heel strike:

%   The first row of MM gives angular momentum of whole system about heel
%   contact, with MM(1,:)*thetadotplus
%   The second row of MM gives angular momentum of trailing leg about hip
%   with MM(2,:)*thetadotplus

MM(1,1) = 0;
MM(1,2) = 1;
MM(2,1) = 1;
MM(2,2) = 0;

unew = MM\amb;  % solve for thetadotplus with a linear system

xnew = [xminus(2); xminus(1); unew(2); unew(1)];
% note leg positions are switched here

end % heelstrike simplest walker

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function energy = energysimpwalk2(t, x)
% given a list of times and states, return the energy of the
% simplest walking model for each time step

% The following variables are available in this
% subfunction:  gamma M L g Kp

if length(t) == 1 % we're given a single time step
  x = x(:)';      % make sure it's a single row vector
end

q1 = x(:,1); q2 = x(:,2); u1 = x(:,3); u2 = x(:,4); % state assignments
  
PEg = M*g*L*cos(q1 - gamma); % gravitational potential energy
PEs = 0.5*Kp*(q2-q1).^2;     % spring potential energy 
KE  = 0.5*M*(u1*L).^2;       % kinetic energy

energy = PEg + PEs + KE;

end % energy simplest walker


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function animatesimpwalk2(x,numsteps,outputflag)
% animatesimpwalk2(x, numsteps) 
%   animates the 2-d simplest walking model simulation
%   x should contain one full step of the states, [q1 q2 u1 u2] arranged
%   in rows.  numsteps is the # of steps to walk (the states in x are
%   repeated automatically for numsteps > 1).  An alternative way to
%   call animateawalk2 is if x contains multiple steps, then numsteps
%   can be a vector containing the starting indices for each of the
%   multiple steps.
%   To have the program save each frame as an adobe illustrator file,
%   use animatesimpwalk2(x, numsteps, 1)

debg = 0; % set this to 1 to step through animation frame by frame

% The following parameters are either accessed from workspace or
% may be defined explicitly:  L (leg length), R (foot radius)

L = 1; % choose foot length = 1
R = 0; % there's no foot arc, so the radius is 0

footn = 10; % number of segments to draw foot with

xlen = length(x);

if nargin < 2, numsteps = []; end;

if length(numsteps) > 1  % numsteps is a list of step lengths
  steplist = numsteps;
  numsteps = length(numsteps);
  endindex = cumsum(steplist);
  startindex = [1 endindex-1];
else                     % numsteps is just a scalar # of steps
  if nargin < 2 | isempty(numsteps)
    numsteps = 2;        % default 2 if unspecified in input
  end
  % now convert it into a list of step lengths
  steplist = [xlen repmat(xlen-1, 1, numsteps-1)];
  endindex = repmat(xlen, numsteps, 1);
  %startindex = [1; repmat(2, numsteps-1, 1)];
  startindex = repmat(1,numsteps,1); % extra frame
end
% Now numsteps contains the number of steps, steplist
% contains the number of frames in each step, and
% startindex and endindex contain indices for each step

if nargin < 3 | isempty(outputflag)
  outputflag = 0;
end

% Estimate range of walking
distance = 2*numsteps*R*x(1,1)+(numsteps+1)*((L-R)*abs(sin(x(1,1))-sin(x(1,2))));
buffer = 0.1;
xlimit = [-buffer distance+buffer]-L*abs(sin(x(1,1))-sin(x(1,2))); 
ylimit = [-0.05 1.35];

aang = pi/6; scale = 0.02; scale2 = 2; vx2 = 0.4; vy2 = 1.2;
alpha = x(1,1); % an estimate of the maximum leg angle

% A foot

% foot starts at -sin(a),cos(a)
% and goes to sin(a),cos(a)
footang = linspace(-alpha*1.1, alpha*1.1, footn);
footxy = R*[sin(footang); -cos(footang)];

% Initialize
clf; 
th1 = x(1,1); th2 = x(1,2); u1 = x(1,3);
contactpoint = 0;
Rot1 = [cos(th1) -sin(th1); sin(th1) cos(th1)];
Rot2 = [cos(th2) -sin(th2); sin(th2) cos(th2)];

footx1 = Rot1(1,:)*footxy + contactpoint; footy1 = Rot1(2,:)*footxy + R;
legsxy = [0  -sin(th1)  -sin(th1)+sin(th2);
  0   cos(th1)   cos(th1)-cos(th2)];
legsx = legsxy(1,:) + contactpoint + R*sin(th1);
legsy = legsxy(2,:) + R - R*cos(th1);       
footx2 = Rot2(1,:)*footxy + legsx(3) - R*sin(th2);
footy2 = Rot2(2,:)*footxy + legsy(3) + R*cos(th2);
pcm = legsxy(:,2) + [contactpoint+R*sin(th1);R-R*cos(th1)];
vcm = [-u1*(R + (L-R)*cos(th1)); -u1*(L-R)*sin(th1)];
velang = atan2(vcm(2),vcm(1));
velx = [0 vcm(1) vcm(1)-scale*cos(velang+aang) NaN vcm(1) vcm(1)-scale*cos(velang-aang)]+pcm(1);
vely = [0 vcm(2) vcm(2)-scale*sin(velang+aang) NaN vcm(2) vcm(2)-scale*sin(velang-aang)]+pcm(2);
velx2 = scale2*[0 vcm(1) vcm(1)-scale*cos(velang+aang) NaN vcm(1) vcm(1)-scale*cos(velang-aang)]+vx2;
vely2 = scale2*[0 vcm(2) vcm(2)-scale*sin(velang+aang) NaN vcm(2) vcm(2)-scale*sin(velang-aang)]+vy2;

set(gcf, 'color', [1 1 1]); set(gca,'DataAspectRatio',[1 1 1],'Visible','off','NextPlot','Add','XLim',xlimit,'YLim',ylimit);

hf1 = line(footx1,footy1,'Marker','.','MarkerSize',20); 
hf2 = line(footx2,footy2,'Marker','.','MarkerSize',20);
hlegs = line(legsx,legsy,'LineWidth',3);
hvel = line(velx,vely,'color','m','LineWidth',2);
hpelv = plot(legsx(2),legsy(2),'.','MarkerSize',30);
hgnd = line(xlimit,[0 0]-.01,'color',[0 0 0],'linewidth',2);

th1old = th1; cntr = 1;
for j = 1:numsteps
  for i = startindex(j):endindex(j)
    th1 = x(i,1); th2 = x(i,2);
    contactpoint = contactpoint - (th1-th1old)*R; % roll forward a little
    th1old = th1;
    Rot1 = [cos(th1) -sin(th1); sin(th1) cos(th1)];
    Rot2 = [cos(th2) -sin(th2); sin(th2) cos(th2)];
    
    footx1 = Rot1(1,:)*footxy + contactpoint; footy1 = Rot1(2,:)*footxy + R;
    legsxy = [0  -sin(th1)  -sin(th1)+sin(th2);
              0   cos(th1)   cos(th1)-cos(th2)];
    legsx = legsxy(1,:) + contactpoint + R*sin(th1);
    legsy = legsxy(2,:) + R - R*cos(th1);       
    footx2 = Rot2(1,:)*footxy + legsx(3) - R*sin(th2);
    footy2 = Rot2(2,:)*footxy + legsy(3) + R*cos(th2);
    
    pcm = legsxy(:,2) + [contactpoint+R*sin(th1);R-R*cos(th1)];
    vcm = [-u1*(R + (L-R)*cos(th1)); -u1*(L-R)*sin(th1)];
    velang = atan2(vcm(2),vcm(1));
    velx = [0 vcm(1) vcm(1)-scale*cos(velang+aang) NaN vcm(1) vcm(1)-scale*cos(velang-aang)]+pcm(1);
    vely = [0 vcm(2) vcm(2)-scale*sin(velang+aang) NaN vcm(2) vcm(2)-scale*sin(velang-aang)]+pcm(2);
    velx2 = scale2*[0 vcm(1) vcm(1)-scale*cos(velang+aang) NaN vcm(1) vcm(1)-scale*cos(velang-aang)]+vx2;
    vely2 = scale2*[0 vcm(2) vcm(2)-scale*sin(velang+aang) NaN vcm(2) vcm(2)-scale*sin(velang-aang)]+vy2;
    
    set(hf1,'Xdata',footx1,'Ydata',footy1);
    set(hf2,'Xdata',footx2,'Ydata',footy2);
    set(hlegs,'Xdata',legsx,'Ydata',legsy);
    set(hvel,'Xdata',velx,'Ydata',vely);
    set(hpelv,'Xdata',legsx(2),'Ydata',legsy(2));
    %set(hvel2,'Xdata',velx2,'Ydata',vely2);
    if 0
    if i==1 & j > 1  % stick velocity arrow
      hveli=line(velx2,vely2,'color','m','LineWidth',2);
      oldx = get(hvelo,'xdata'); oldy = get(hvelo,'ydata');
      hsang = atan2(vely2(2)-oldy(2),velx2(2)-oldx(2));
      velxh = [oldx(2) velx2(2) velx2(2)-scale2*scale*cos(hsang+aang) NaN velx2(2) velx2(2)-scale2*scale*cos(hsang-aang)];
    	velyh = [oldy(2) vely2(2) vely2(2)-scale2*scale*sin(hsang+aang) NaN vely2(2) vely2(2)-scale2*scale*sin(hsang-aang)];  
  		hvelhs = line(velxh,velyh,'color','r','Linewidth',2);    
    end
    end
    drawnow; pause(0.05)
    if outputflag
      print('-dill',sprintf('walk%02d',cntr));
    end
    if debg, pause, end;
    cntr = cntr + 1;
  end
  contactpoint = contactpoint - (L-R)*(sin(th1)-sin(th2)); th1old = th2;
	%hvelo = line(velx2,vely2,'color','m','LineWidth',2);
end

end % animate function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end % simplest walking model file


