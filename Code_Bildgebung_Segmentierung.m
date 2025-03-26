% Projektarbeit Bildgebung in der Therapie WiSe2024/2025
% Code für die Schwellenwertsegmentierung
% Abgabe von Melanie Hartmann, Sophie Scholtyssek


clear all;
close all;

% 1. Bild laden
% Für curved-Array
image_pre = imread(['110.png']);
% Für linear-Array
%image_pre = imread([linear_array\with_needle_phantom2\450.png']);

figure, imshow(image_pre); title('Originalbild');
image = imcrop(image_pre, [300 70 750 470]);
imshow(image);

% 2. Falls RGB, in Graustufen umwandeln
if size(image, 3) == 3
    grayImage = rgb2gray(image);
else
    grayImage = image;
end

% 3. Kontrast verbessern
enhancedImage = imadjust(grayImage);
figure, imshow(enhancedImage); title('Kontrastverstärktes Bild');

% 4. Rauschreduktion mit Medianfilter
smoothedImage = medfilt2(enhancedImage, [5 5]);
figure, imshow(smoothedImage); title('Rauschreduziertes Bild');

% 5. Schwellenwertsegmentierung
binaryImage= imbinarize(smoothedImage, 0.45); % für cureved-Array
%binaryImage = imbinarize(smoothedImage, 0.5);   % für linear-Array 
figure, imshow(binaryImage); title('Binärbild nach Schwellenwertsegmentierung');

% 6. Morphologische Verarbeitung zur Verbesserung der Segmentierung
binaryImage = imdilate(binaryImage, strel('disk', 1)); % Bereiche vergrößern
binaryImage = bwareaopen(binaryImage, 1000); % Kleine Objekte entfernen
figure, imshow(binaryImage); title('Nach Morphologischer Verarbeitung');

% 7. Objekte nummerieren und farbig darstellen
L = bwlabel(binaryImage); % Objekte nummerieren
RGB = label2rgb(L, 'jet', 'k', 'shuffle'); % Zufällige Farben für Objekte
figure, imshow(RGB); title('Segmentierte Objekte');
hold on;

% 8. Objekterkennung mit RegionProps
props = regionprops(binaryImage, 'BoundingBox', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');

% Objekte mit Nummern markieren (hilft bei der Orientierung und
% Beeinflussung der Parameter)
 for i = 1:length(props)
     bbox = props(i).BoundingBox;
     x = bbox(1) + bbox(3)/2; % Mittelpunkt der BoundingBox (X)
     y = bbox(2) + bbox(4)/2; % Mittelpunkt der BoundingBox (Y)
     text(x, y, num2str(i), 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
 end

 hold off;

% In diesem Fall soll die Nadel mit einem Rechteck gekennzeichnet werden.
% Durch Anpassung an die Bedingungen der detektierten Fläche in der Box,
% können so gemäß Ausschlusskriterin wie der Länge, dem Seitenverhältnis
% sowie der Orientierung unterschieden werden, ob es sich um eine
% Biopsienadel oder um Gewebe handelt. Um die Nadel visuell sichtbar zu
% machen, könnte anstelle der folgenden Codes auch mit diesem hier
% gearbeitet werden:

    %% 9. Bereich der erkannten Nadeln rot einfärben
    % colorMask = cat(3, binaryImage, zeros(size(binaryImage)), zeros(size(binaryImage)));
    %%  Markiert den Bereich, der als Objekt erkannt wird, rot
    
    %% Überlagerung der Maske mit 50% Transparenz
    %overlayImage = imoverlay(grayImage, binaryImage, [1 0 0]); % Rot einfärben
    
    %% 10. Ergebnis anzeigen
    %figure, imshow(overlayImage); title('Erkannte Nadeln hervorgehoben');

% Hier geht der Code für die Verwendung von Rechtecksmarkierungen weiter
% 9. Bounding Boxen extrahieren
props = regionprops(binaryImage, 'BoundingBox', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');

% Liste für gültige Bounding Boxen
validBoxes = [];

for i = 1:length(props)
    majorAxis = props(i).MajorAxisLength;
    minorAxis = props(i).MinorAxisLength;
    aspectRatio = majorAxis / minorAxis;
    orientation = abs(props(i).Orientation);
    width = props(i).BoundingBox(3);

    % Filterung der Bounding Boxes nach Merkmalen -> nur Biopsienadelformen
    % sollen akzeptiert werden
    if majorAxis > 15 && aspectRatio > 3 && width < 900 && orientation > 10
        bbox = props(i).BoundingBox;

        % Bounding Box leicht vergrößern
        bbox(1) = bbox(1) - 0.05 * bbox(3);
        bbox(2) = bbox(2) - 0.05 * bbox(4);
        bbox(3) = bbox(3) * 1.1;
        bbox(4) = bbox(4) * 1.1;

        validBoxes = [validBoxes; bbox]; % Speichern der Bounding Box
    end
end

% 10. Bounding Boxes zusammenfassen, falls sie sich überlappen ->
% Zugehörigkeit zu einer Biopsienadel erstellen
mergedBoxes = mergeBoundingBoxes(validBoxes);

% 11. Erkannte Nadeln anzeigen
figure, imshow(image); title('Erkannte Nadel');
hold on;
for i = 1:size(mergedBoxes, 1)
    rectangle('Position', mergedBoxes(i, :), 'EdgeColor', 'r', 'LineWidth', 3);
end
hold off;

%% Funktion zur Zusammenfassung überlappender Bounding Boxes
function mergedBoxes = mergeBoundingBoxes(bboxList)
    if isempty(bboxList)
        mergedBoxes = [];
        return;
    end

    % Sortiere die Boxen nach X-Position für effiziente Gruppierung
    bboxList = sortrows(bboxList, 1);
    mergedBoxes = bboxList(1, :); % Erste Box hinzufügen

    for i = 2:size(bboxList, 1)
        newBox = bboxList(i, :);
        lastBox = mergedBoxes(end, :);

        % Prüfen, ob sich die neue Box mit der letzten überschneidet
        if (newBox(1) < lastBox(1) + lastBox(3)) && (newBox(1) + newBox(3) > lastBox(1)) && (newBox(2) < lastBox(2) + lastBox(4)) && (newBox(2) + newBox(4) > lastBox(2))

            % Zusammenführen der beiden überlappenden Boxen
            mergedX = min(lastBox(1), newBox(1));
            mergedY = min(lastBox(2), newBox(2));
            mergedW = max(lastBox(1) + lastBox(3), newBox(1) + newBox(3)) - mergedX;
            mergedH = max(lastBox(2) + lastBox(4), newBox(2) + newBox(4)) - mergedY;

            mergedBoxes(end, :) = [mergedX, mergedY, mergedW, mergedH]; % Update der letzten Box
        else
            mergedBoxes = [mergedBoxes; newBox]; % Falls keine Überlappung, neue Box hinzufügen
        end
    end
end
