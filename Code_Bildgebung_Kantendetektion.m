% Projektarbeit Bildgebung in der Therapie WiSe2024/2025
% Code für Segmentierung
% Abgabe von Melanie Hartmann, Sophie Scholtyssek

%Bild laden und zuschneiden
clear;
img = imread('110.png'); %hier anhand Beispielbield 110 vom Curved-Array mit Nadel 
cropped = imcrop(img,[300 70 750 470]);

%Kantenfilter anwenden
grey = im2gray(cropped); 
edges = edge(grey, 'canny', 0.3);

%erkannte Kanten hervorheben
fat = strel('disk', 2);
edges_fat = imdilate(edges, fat);

% Überlagern der Kanten auf das Originalbild und Einfärben der Kanten
img_edges = imoverlay(cropped, edges_fat, [1, 0, 0]); 

% Anzeigen des Ergebnisses
imshow(img_edges);