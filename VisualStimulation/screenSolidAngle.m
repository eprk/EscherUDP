function sa = screenSolidAngle(w,h,d)
% To compute the dots/sr, we approximate the screen with a
% circle C of the same area and centered to the screen center,
% and we compute its solid angle.
% A circle C of area w*h (screen width and height) has a radius R
% of sqrt(w*h/pi).

R = sqrt(w*h/pi);
% The radius of a sphere S whose center is the observer
% (at a distance d from the screen) and whose intersection with
% the screen is C is r = sqrt(d^2+R^2). Indeed, the observer is
% at distance d from the center of the screen (i.e. the center
% of C), so d, R and r are respectively the catheti (legs) and
% hypthenuse or a right triangle.
r = sqrt(d^2+R^2);
% The area A of the circular cap identified by C on the sphere S
% is given by the formula 2*pi*r*h, where h is the height of
% the cap (h is simply r-d).
% The solid angle "sa" occupied by C is, by definition A/r^2, which
% simplifies to 2*pi*h/r = 2*pi*(r-d)/r = 2*pi*(1-d/r)
sa = 2*pi*(1-d/r);
end