function pfm_post
% Design summary: A function to postprocess output from profilometer
% Capability: 
%      1. Read raw profilometer output & plot a 3D surface
%      2. Remove the gradient from the profilometer reading

linefns = {};
surffns = {};

%% Settings
ringSel = 1;


%% Body
inputfn = '2019-8-14_raw.mat';
load(inputfn, 'height_ls', 'intens_ls')  % Loads into height_ls, intens_ls
% linefns = {'spline', 'cubicspline', 'smoothingspline', 'nearestinterp', 'pchipinterp'};
linefns = {'poly1', 'poly2', 'poly3'};
% surffns = {'test'};
% surffns = {'lowess', 'loess', 'biharmonicinterp', 'thinplateinterp'};
% surffns = {'poly11', 'poly22', 'poly33'};

nx = numel(linefns);
ny = numel(surffns);

X = height_ls(:, 1);
Y = height_ls(:, 2);
H = height_ls(:, 3);
I = intens_ls(:, 3);

switch ringSel
    case 0  % Plot intensity
        X = intens_ls(:, 1);
        Y = intens_ls(:, 2);
        H = intens_ls(:, 3);
    case 1  % First ring
        [X, Y, H] = remove_last_two_rings(X, Y, H);
    case 2  % Middle ring
        [X, Y, H] = remove_first_last_rings(X, Y, H);
    case 3  % Last ring
        [X, Y, H] = remove_first_two_rings(X, Y, H);
    otherwise  %  All rings, no normalization
        H(H<0) = 0;
        H(isnan(H)) = 0;
end

% fprintf('Corr2 (I, H) is: %1.3f\n', corr2(I, H));

if nx == 0
    idxitr = ny;
else
    idxitr = nx;
end

fig1 = figure;
if nx ~=0 && ny ~=0
    subplot(nx, ny, 1);
elseif nx + ny > 1
    sub_ax = tight_subplot(1, max(nx, ny), 0.01, [0.1, 0.1], [0.04, 0.06]);
else
    sub_ax = gca;
end

line_then_surf = false;

if 0 
    for i = 1:nx
        for j = 1:ny
            switch ringSel
                case 0  % Plot intensity
                case {1, 2, 3}  % Rings
                    H_post{i, j} = H;
                    if line_then_surf
                        H_post{i, j} = remove_gradient_line(X, Y, H_post{i, j}, linefns{i});
                        H_post{i, j} = remove_gradient_surf(X, Y, H_post{i, j}, surffns{j});
                    else
                        H_post{i, j} = remove_gradient_surf(X, Y, H_post{i, j}, surffns{j});
                        H_post{i, j} = remove_gradient_line(X, Y, H_post{i, j}, linefns{i});
                    end
                otherwise  %  All rings, no normalization
            end

            figure(fig1)
            subplot(nx, ny, (i-1)*ny + j);
            H_post{i, j} = slide_height(50, H_post{i, j});
            scatter(X, Y, 10, H_post{i, j}, 'filled', 'sq')
            xlim([min(X)-1.8*3, max(X)+1.8*3])
            caxis([0 100])
            
            if line_then_surf
                title(sprintf('Line fit = %s, Surf fit = %s', linefns{i}, surffns{j}));
            else
                title(sprintf('Surf fit = %s, Line fit = %s', surffns{j}, linefns{i}));
            end
            
            % Misc Formatting/Labelling
            ax = gca;
            ax.XTick = linspace(0, max(X), 5);
            ax.XTickLabel = {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'};
            xlabel('\theta')
            ylabel('Distance in Flow Direction [mm]')
            h = colorbar;
            ylabel(h, 'Degraded Height [-]')
            colormap(brewermap(64, 'Spectral'))
            grid on
            box on
        end
    end
end


if 1
    for i = 1:idxitr
            switch ringSel
                case 0  % Plot intensity
                    H_post{i} = H;
                case {1, 2, 3}  % Rings
                    if (ringSel == 2 || ringSel == 3)
                        [X, Y, H] = remove_outliers(X, Y, H); 
                    end
                    H_post{i} = H;
                    if nx == 0
                        H_post{i} = remove_gradient_surf(X, Y, H_post{i}, surffns{i});
                    else
                        H_post{i} = remove_gradient_line(X, Y, H_post{i}, linefns{i});
                    end
                    % Increasing so that MIN value of Heights = 0
                    [H_post{i}, stdH] = slide_height(H_post{i});
                otherwise  %  All rings, no 
                    H_post{i} = H;
            end

            
            axes(sub_ax(i));
            scatter(X, Y, 10, H_post{i}, 'filled', 'sq')
            xlim([min(X)-1.8*3, max(X)+1.8*3])
            caxis([0 round(max(H_post{i}),-1)+5])

            if nx == 0 && ny > 1
                title(sprintf('Surf fit = %s', surffns{i}));
            elseif ny == 0 && nx > 1
                title(sprintf('Line fit = %s', linefns{i}));
            end

            % Misc Formatting/Labelling
            ax = gca;
            ax.XTick = linspace(0, 360, 5);
            ax.XTickLabel = {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'}
            grid on
            box on
            if i == 1
                ylabel('Distance in Flow Direction [mm]')
            end
            if i == idxitr
                h = colorbar;
                if nx > 1 || ny > 1
                    h.Position(1) = 0.95;
                end
                ylabel(h, 'Height [\mum]')
            end
    end
    
    if nx > 1 || ny > 1
        for i = 2:max(nx, ny)
            set(sub_ax(i), 'YTickLabel', '');
        end
        ax = gcf;
        ax.Position = [285 197 1632 228];
        ax.Renderer = 'painters';
        maxH = 0;
        for i = 1:numel(H_post)
            maxH = max(maxH, max(H_post{i}));
        end
        for i = 1:numel(H_post)
            axes(sub_ax(i));
            caxis([0 round(maxH,-1)+5])
        end
    end
end



end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [H, stdH] = slide_height(H)
    stdH = 3*std(H);
    H = H + stdH;
end

function [X, Y, H] = remove_last_two_rings(X, Y, H)
    mask = (X > 20) & (X < 310) & (Y > 4.5) & (Y < 12); % For Swirl_2
    X = X(mask);
    Y = Y(mask);
    H = H(mask);
end

function [X, Y, H] = remove_first_last_rings(X, Y, H)
    mask = (X > 20) & (X < 310) & (Y > 13.5) & (Y < 24.5);
    X = X(mask);
    Y = Y(mask);
    H = H(mask);
end

function [X, Y, H] = remove_first_two_rings(X, Y, H)
    mask = (X > 20) & (X < 310) & (Y > 26.0) & (Y < 37.0);
    X = X(mask);
    Y = Y(mask);
    H = H(mask);
end

function H = remove_gradient(X, Y, H, ptype)
    plotBool = true;
    thetas = unique(X);
    %
    if plotBool
    figure
    subplot(2, 1, 2), hold on, box on, grid on
    ylabel('Adjusted Height [\mum]'), xlabel('Distance in Fow Direction [mm]')
    ax = gca; set(ax, 'DefaultLineLinewidth', 1.5);
    subplot(2, 1, 1), hold on, box on, grid on
    ax = gca; set(ax, 'DefaultLineLinewidth', 1.5);
    ylabel('Raw Height [\mum]'), xlabel('Distance in Fow Direction [mm]')
    end
    %
    for i = 1:numel(thetas)
        mask = X==thetas(i);
        %%%%%%%%%%
        p = fit(Y(mask), H(mask), ptype);
        peval = p(Y(mask));
        %%%%%%%%%%
        if ~mod(i-1, 25) && plotBool  % Plot slope every XX theta
            tspr = sprintf('Theta %1.2f deg', thetas(i));
            subplot(2, 1, 1), hold on
            plot(Y(mask), H(mask), 'DisplayName', strcat(tspr, ' Raw'));
            if ax.ColorOrderIndex > 1, ax.ColorOrderIndex = ax.ColorOrderIndex - 1; end;
            plot(Y(mask), peval, '--', 'DisplayName', strcat(tspr, ' Fit'));
            %
            H(mask) = H(mask) - peval;  % Subtract fit
            subplot(2, 1, 2), hold on
            plot(Y(mask), H(mask), 'DisplayName', strcat(tspr, ' Adj'));
        else
            H(mask) = H(mask) - peval;
        end
    end
    %
    if plotBool
       subplot(2, 1, 1)
       legend('Location','EastOutside')
       subplot(2, 1, 2)
       legend('Location','EastOutside')
    end
end
 

function H = remove_gradient_line(X, Y, H, ptype)
    thetas = unique(X);
    for i = 1:numel(thetas)
        mask = X==thetas(i);
        %%%%%%%%%%
        p = fit(Y(mask), H(mask), ptype, 'Normalize', 'on');
        peval = p(Y(mask));
        %%%%%%%%%%
        H(mask) = H(mask) - peval;
    end
    %
end

function [X, Y, H] = remove_outliers(X, Y, H)
    [H, mask] = rmoutliers(H);
    X = X(~mask);
    Y = Y(~mask);
end

function H = remove_gradient_surf(X, Y, H, ptype)
    % Notes:
       % 1. polyXX fits do not work well.. Just Kidding!
       % 2. loess did not work well...  lowess took very long
    thetas = unique(X);
    %
    excvec = Y > 310;
    fitsurf = fit([X Y], H, ptype, 'Exclude', excvec, 'Normalize', 'on');
    for i = 1:numel(thetas)
        mask = X==thetas(i);
        H(mask) = H(mask) - feval(fitsurf, [X(mask), Y(mask)]);
    end
end
