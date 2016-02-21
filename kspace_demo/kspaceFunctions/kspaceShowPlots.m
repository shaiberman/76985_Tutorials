function [kspace M] = kspaceShowPlots(f, spins, gradients,...
    kspace, im, params, t, b0noise, M)  
% [kspace M] = kspaceShowPlots(f, spins, gradients,...
%    kspace, im, params, t, b0noise, M)

% if we are not done filling kspace, and we are not showing step by step
% progress, then return without doing anything
if t < length(kspace.vector.x) && params.showProgress == false
    return;
end

% Otherwise recon and plot!
kspace = kspaceRecon(kspace, params);

% ********************************
% Image and Recon
% ********************************

% set up plots and subplots
rows = 3; cols = 4; n = 1;

% Check to see if this is the first time we are plotting this recon. If so,
% we will need to set up the plots. If not, we can skip some steps.
userData = get(f, 'UserData');
if isfield(userData, 'initialized') && t > 1
    initialize = false;
else
    initialize = true;
    userData.initialized = true;
    set(f, 'UserData', userData);
end

if initialize, 
    figure(f); clf; 
    colormap (gray); 
end

figure(f)

%-----------------------------------
% Plot 3: kspace filled by imaging
%-----------------------------------
subplot(rows,cols,5)
tmp = fftshift(log(abs((kspace.grid.real + 1i*kspace.grid.imag))));
x = fftshift(kspace.grid.x);
y = fftshift(kspace.grid.y);
ma = max([tmp(isfinite(tmp)); 0]);
mi = min([tmp(isfinite(tmp)); 0]);
if ma <= mi, ma = 1; mi = 0; end
set(gca, 'CLim', [mi ma]);
if initialize,
    cla
    imagesc(x(:), y(:), tmp);
    axis image square;    
    title('kspace filled by imaging')
    xlabel('cycles per meter'); ylabel('cycles per meter')
    hold on;
else
    imagesc(x(:), y(:), tmp);
end
%-----------------------------------
% Plot 4: image reconned from kspace
%-----------------------------------1
subplot(rows,cols,6);
recon = abs(ifft2(kspace.grid.real + 1i*kspace.grid.imag));
imsize = [0 params.imSize*100];
if initialize,
    cla
    imagesc(imsize, imsize, recon);
    axis image;
    title('image reconned from kspace')
    xlabel('mm'); ylabel('mm')
    grid on
    ticks = linspace(0, max(imsize), 11);
    set(gca, 'YTick', ticks)
    set(gca, 'XTick', ticks);
    set(gca, 'GridLineStyle', '-')
    set(gca,'Xcolor',[1 1 1]);
    set(gca,'Ycolor',[1 1 1]);
    hold on;
else
    imagesc(imsize, imsize, recon);
end


%-----------------------------------
% Plot 1: kspace computed from image
%-----------------------------------
subplot(rows,cols,1)
imagesc(x(:), y(:), im.fftshift);
if initialize,
    cla
    imagesc(x(:), y(:), im.fftshift);
    axis image;
    title('kspace computed from image')
    xlabel('cycles per meter'); ylabel('cycles per meter')
    hold on;
end
    
%-----------------------------------
% Plot 2: Original Image
%-----------------------------------
subplot(rows,cols,2)
if initialize,
    cla
    imagesc(imsize, imsize, im.orig);
    axis image;
    title('Original Image');
    xlabel('mm'); ylabel('mm')
    grid on
    set(gca, 'YTick', ticks)
    set(gca, 'XTick', ticks);
    set(gca, 'GridLineStyle', '-')
    set(gca,'Xcolor',[1 1 1]);
    set(gca,'Ycolor',[1 1 1]);
    hold on;
else
    imagesc(imsize, imsize, im.orig);
end


% ********************************
% Gradients & Spins
% ********************************

%-----------------------------------
% Plot 5: Sinusoidal spin channel
%-----------------------------------
subplot(rows,cols,9);
if initialize, 
    cla
    imagesc(real(spins.total));        
    
    axis image;
    title(sprintf('REAL: x=%2.1f cpm, y=%2.1f cpm', kspace.vector.x(t), kspace.vector.y(t)));
    hold on
else
    imagesc(real(spins.total));
end

% ********************************
% B0 Map
% ********************************
subplot(rows,cols,10);
if initialize,
    cla
    imagesc(imsize, imsize, b0noise)
    axis image;
    noiseMin = min(b0noise(:)) * params.gamma / (2 * pi);
    noiseMax = max(b0noise(:)) * params.gamma / (2 * pi);
    title(sprintf('B0 map. Range = [%2.1f %2.1f] Hz', noiseMin, noiseMax))
    xlabel('mm'); ylabel('mm')
    grid on
    set(gca, 'YTick', ticks)
    set(gca, 'XTick', ticks);
    set(gca, 'GridLineStyle', '-')
    set(gca,'Xcolor',[1 1 1]);
    set(gca,'Ycolor',[1 1 1]);
    hold on;
else
    imagesc(imsize, imsize, b0noise)
end

%%
%figure(f+1)
% %-----------------------------------
% % Plot 6: Cosinusoidal spin channel
% %-----------------------------------
% subplot(2,1,1)
% imagesc(imag(spins.total));
% if initialize, axis image off; hold on; end
% title(sprintf('IMAGINARY: x=%2.1f cpm, y=%2.1f cpm', kspace.vector.x(t), kspace.vector.y(t)));

%-----------------------------------
% Gradients
%-----------------------------------
subplot(rows,cols,3:4)
if initialize,
    cla
    axis tight ; 
    ylim([-1.1 1.1]*max(gradients.x));
    xlim([0 sum(gradients.T)]);
    title('x Gradients');
    hold on;
end
plot([0 cumsum(gradients.T(1:t))], [gradients.y(1) gradients.y(1:t)], 'g-', 'LineWidth', 1);


subplot(rows,cols,7:8)
if initialize,
    cla
    axis tight ; 
    ylim([-1.1 1.1]*max(gradients.x));
    xlim([0 sum(gradients.T)]);
    title('y Gradients');
    hold on
end
plot([0 cumsum(gradients.T(1:t))], [gradients.x(1) gradients.x(1:t)], 'r-', 'LineWidth', 1);

subplot(rows,cols,11:12); hold on;
if initialize 
noversample = 2;
plot(kspace.vector.x(1:end/noversample), kspace.vector.y(1:end/noversample), 'bo-')
plot(kspace.vector.x((1:end/noversample)+end/noversample), kspace.vector.y((1:end/noversample)+end/noversample), 'ro-')
%plot(kspace.vector.x(1), kspace.vector.y(1), 'rx')
title('K Space trajectories')
xlabel('frequency (cycles per meter)')
ylabel('frequency (cycles per meter)')
axis square tight
grid on
end
end
