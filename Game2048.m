classdef Game2048 < handle
   

    properties (SetAccess = protected)
        hFig    % Handle of main UI        
    end
    
    properties (Access = protected)
        Game    % TwentyFortyEight game object
        Blocks  % Array of GameBlock objects
                               
        hHistoryAxes    % Handle of the plot showing score history
        hCurrentScoreLine   % Handle of current score plot
        
        hAllScoresTable     % Handle of table showing all scores
        
        hScore  % Handle of text object displaying current score
        hMoves  % Handle of text object displaying current move number
        
        Animation = true    % Flag indicating whether to animate
        HistoryDisplay = false      % Flag indicating whether to display history
                
        iconData    % Icon CDATA for toolbar
        
        hToolbarButtons
        
        lhMoved
        lhGameOver
        lhGameWon
    end
    
    properties (Access = protected, Constant)
        xPts = repmat(0.5:3.5, 4, 1)    % X coordinates of blocks
        yPts = repmat((3.5:-1:0.5)', 1, 4)  % Y coordinates of blocks
    end
    
    properties (Access = protected, Dependent)
        ScreenSize  % Screen size ([width height])
    end
    
    methods
        function obj = Game2048
            % Construct game object
            obj.Game = TwentyFortyEight(true);
           
             [y,fs] = audioread ('CB.mp3');

      sound(y,fs);
            
      % Add event listeners 
            obj.lhMoved = event.listener(obj.Game, 'Moved', @obj.updateBlocks);
            obj.lhGameOver = event.listener(obj.Game, 'GameOver', @obj.GameOver);
            obj.lhGameWon = event.listener(obj.Game, 'YouWin', @obj.GameWon);
                        
            % Construct main UI
            obj.hFig = figure(...
                'NumberTitle', 'off', ...
                'Name', '2048 MATLAB', ...
                'HandleVisibility', 'on', ...
                'Toolbar', 'none', ...
                'Menu', 'none', ...
                'Color', 'white', ...
                'Units', 'Pixels', ...
                'Position', [obj.ScreenSize/2-[210, 240], 420, 480], ...
                'Visible', 'on', ...
                'BusyAction', 'cancel', ...
                'Interruptible', 'off', ...
                'Resize', 'off', ...
                'DockControl', 'off', ...
                'DeleteFcn', @obj.figDelFcn, ...
                'WindowKeyPressFcn', @obj.KeyPressFcn);
            
            % Construct toolbar
            obj.iconData = load(fullfile(fileparts(mfilename), 'iconData'));
            hToolbar = uitoolbar(...
                'Parent', obj.hFig);
            obj.hToolbarButtons(1) = uipushtool(...
                'Parent', hToolbar, ...
                'CData', obj.iconData.new, ...
                'TooltipString', 'New game', ...
                'ClickedCallback', @obj.newGame);
          
            
         
       
            % Construct main axes
            hAx = axes(...
                'Parent', obj.hFig, ...
                'Units', 'Pixels', ...
                'Position', [10 10 400 400], ...
                'Color', [36 220 36]/255, ...
                'XLim', [0 4], ...
                'YLim', [0 4], ...
                'XTick', [], ...
                'YTick', [], ...
                'XColor', [255 255 255]/255, ...
                'YColor', [255 255 255]/255, ...
                'Box', 'on', ...
                'XTickLabel', [], ...
                'YTickLabel', [], ...
                'PlotBoxAspectRatio', [1 1 1]);
            
            obj.hScore = uicontrol(...
                'Parent', obj.hFig, ...
                'Units', 'Pixels', ...
                'Position', [300 420 120 50], ...
                'Style', 'Text', ...
                'FontUnits', 'Pixels', ...
                'FontSize', 16, ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', get(obj.hFig, 'Color'), ...
                'String', sprintf('Score: 0\nHighScore: %d', obj.Game.HighScore));
            obj.hMoves = uicontrol(...
                'Parent', obj.hFig, ...
                'Units', 'Pixels', ...
                'Position', [10 420 260 50], ...
                'Style', 'Text', ...
                'FontUnits', 'Pixels', ...
                'FontSize', 16, ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', get(obj.hFig, 'Color'), ...
                'String', sprintf('Moves: %d', obj.Game.NumMoves));
            
            % Background blocks
            GameBlock(obj.xPts(:), obj.yPts(:), ...
                repmat({''}, 16, 1), .9, .9, hAx);
            
            % Game blocks
            obj.Blocks = GameBlock(obj.xPts(:), obj.yPts(:), ...
                repmat({''}, 16, 1), .9, .9, hAx);
            
            % Construct score history panel
            hPanel = uipanel(...
                'Parent', obj.hFig, ...
                'Units', 'Pixels', ...
                'Position', [430 0 400 480]);
            obj.hAllScoresTable = uitable(hPanel, ...
                'Units', 'Pixels', ...
                'Position', [80 350 300 180], ...
                'ColumnName', {'Score', 'Moves', 'Highest block'}, ...
                'ColumnWidth', {50 50, 140});
            obj.hHistoryAxes = axes(...
                'Parent', hPanel, ...
                'Units', 'Pixels', ...
                'Position', [80 50 300 190]);
            updateAllScoresData(obj)

            updateBlocks(obj)
            
            set(obj.hFig, 'Visible', 'on');
       
   
        end
        
        function runAI(obj, varargin)
            % runAI  Run an AI algorithm to solve the puzzle
            
            if strcmp(get(varargin{1}, 'State'), 'off')
                return
            end
            
            % Select a function from the current folder. To make it simple,
            % I only allow running an AI algorithm
            [fn, pn] = uigetfile('*.m', 'Select an AI function', 'MultiSelect', 'off');
            if isnumeric(fn)
                return
            end
            
            % CD to the path so that the function is visible
            cd(pn)
            
            % Create function handle
            [~, n] = fileparts(fn);
            AIfcn = str2func(n);
            
            % Turn off GameWon/GameOver listener temporarily, since I check
            % manually. Also disable other toolbar buttons
            obj.lhGameWon.Enabled = false;
            obj.lhGameOver.Enabled = false;
            set(obj.hToolbarButtons([1 2 4 5 6]), 'Enable', 'off');
            
           
            
          
            
            set(varargin{1}, 'State', 'off')
            set(obj.hToolbarButtons([1 2 4 5 6]), 'Enable', 'on');

            if isGameWon(obj.Game)
                GameWon(obj)
            elseif isGameOver(obj.Game)
                GameOver(obj)
            end

            if isvalid(obj.Game)
                obj.Game.AIMode = false;
            end

            obj.lhGameWon.Enabled = true;
            obj.lhGameOver.Enabled = true;
        end
        
        function val = get.ScreenSize(~)
            set(0, 'Units', 'Pixels')
            sc = get(0, 'ScreenSize');
            val = sc(3:4);
        end
        
        function updateAllScoresData(obj)
            % updateAllScoresData  Refresh score history table and plot
            
            set(obj.hScore, 'String', ...
                sprintf('Score: %d\nBest: %d', max(obj.Game.Scores), obj.Game.HighScore));
            
            if isempty(obj.Game.AllScores)
                data = {};
            else
                %data = table2cell(obj.Game.AllScores(:,[1 3 4]));
                data = [obj.Game.AllScores.FinalScore; obj.Game.AllScores.Moves; obj.Game.AllScores.HighBlock]';
            end
           
            
           
        end
        
        
            
           
        
        function KeyPressFcn(obj, ~, edata)
            % KeyPressFcn  Callback to handle key presses
            
            if any(strcmp(edata.Key, ...
                    {'escape', 'uparrow', 'downarrow', 'rightarrow', 'leftarrow','m','p'}))
                switch edata.Key
                    case 'uparrow'
                        move(obj.Game, 'up');
                         [y,fs] = audioread ('S.wav');

                           sound(y,fs);
                    case 'downarrow'
                        move(obj.Game, 'down');
                         [y,fs] = audioread ('S.wav');

                           sound(y,fs);
                    case 'rightarrow'
                        move(obj.Game, 'right');
                         [y,fs] = audioread ('S.wav');

                           sound(y,fs);
                    case 'leftarrow'
                        move(obj.Game, 'left');
                         [y,fs] = audioread ('S.wav');
                         
                         sound(y,fs);
                    case 'm'
                        pause sound 
                        
                 
                    case 'escape'
                        delete(obj.hFig)
                        clear sound 
                    otherwise
                        return
                end
            end
        end
        
        function figDelFcn(obj, varargin)
            % figDelFcn  Callback when figure is deleted
            
            % Delete the game object - this performs clean up actions
            delete(obj.Game)
            clear sound
        end
        
        function newGame(obj, varargin)
            % newGame  Callback when the "New Game" toolbar button is pressed
            
            if nargin > 1
                btn = questdlg('Restart?', 'New Game', 'Yes', 'No', 'Yes');
                switch btn
                    case 'No'
                        return
                end
            end
            
            % Reset game object
            reset(obj.Game)
            
            % Update the score history
            updateAllScoresData(obj)
            
            % Update the block visualization
            updateBlocks(obj)
        end
        
        function GameWon(obj, varargin)
            % GameWon  Callback when the "YouWin" event is triggered
            
            btn = questdlg({'You won! Congratulations!', '', 'Continue playing?'}, 'You Won', 'Continue playing', 'Play new game', 'Quit', 'Continue playing');
            switch btn
                case 'Continue playing'
                    obj.Game.StopNumber = inf;
                case 'New game'
                    newGame(obj)
                case 'Quit'
                    delete(obj.hFig)
                    clear sound 
            end
        end
        
        function GameOver(obj, varargin)
            % GameOver  Callback when the "GameOver" event is triggered
            
            btn = questdlg({'No more moves', '', 'Play again?'}, 'Game Over', 'Play new game', 'Quit', 'Play new game');
            switch btn
                case 'Play new game'
                    newGame(obj)
                case 'Quit'
                    delete(obj.hFig)
                    clear sound 
            end
        end
        
        function updateBlocks(obj, varargin)
            % updateBlocks  Update the block positions
            
            if ishandle(obj.hFig)
                blocksMoving = obj.Game.Movement ~= reshape(1:16,4,4);
                if nnz(blocksMoving) > 0 && obj.Animation
                    xFrom = obj.xPts(:);
                    yFrom = obj.yPts(:);
                    xTo = obj.xPts(obj.Game.Movement(:));
                    yTo = obj.yPts(obj.Game.Movement(:));
                    
                    % Bring blocks (patches) to the top so that the
                    % animation displays correctly
                    bringToTop(obj.Blocks(blocksMoving));
                    
                    % Animate 15 frames for transition
                    frms = 10;
                    for id = 1:frms
                        set(obj.Blocks, [xFrom+id/frms*(xTo-xFrom), yFrom+id/frms*(yTo-yFrom)], []);
                        drawnow expose
                        %pause(0.01);
                    end    
                end
                
                % Display the final block positions 
                txt = cellfun(@num2str, num2cell(obj.Game.Board), 'UniformOutput', false);
                txt(strcmp(txt, 'NaN')) = {''};
                set(obj.Blocks, [obj.xPts(:), obj.yPts(:)], txt);
                updateColors(obj.Blocks);
               
                set(obj.hScore, 'String', sprintf('Score: %d\nBest: %d', max(obj.Game.Scores), obj.Game.HighScore));
                set(obj.hMoves, 'String', sprintf('Moves: %d', obj.Game.NumMoves));
                
                if obj.HistoryDisplay
                    if obj.Game.NumMoves == 0
                        set(obj.hCurrentScoreLine, 'XData', nan, 'YData', nan)
                        xlim(obj.hHistoryAxes, 'auto')
                    else
                        set(obj.hCurrentScoreLine, 'XData', 1:obj.Game.NumMoves, 'YData', obj.Game.Scores(~isnan(obj.Game.Scores)));
                        xlim(obj.hHistoryAxes, [max(0,obj.Game.NumMoves-25), obj.Game.NumMoves+25])
                    end
                end
            end
        end
                
      
        
        
       
    end
    
end


