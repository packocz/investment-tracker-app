#!/usr/bin/node

console.log('test');

const args = process.argv.slice(2);
const filePath = args[0];
const commentsPath = args[1];

const fs = require('fs');

let lineDiffData;
let comments;
try {
	lineDiffData = fs.readFileSync(filePath, 'utf8');
	comments = JSON.parse(fs.readFileSync(commentsPath, 'utf8'));
} catch (err) {
	console.error(err);
}

function getLineToPositionMaps(diffLines) {
	let lines = diffLines.split('\n');
	let fileToLineMaps = new Map();
	let currentFileName;
	let currentIndex = 1;
	lines.forEach((oneLine) => {
		let fileAndLines = oneLine.split(':');
		let linesInHunk;
		let fileLineMap;
		if (fileAndLines.length === 2) {
			//new file
			currentFileName = fileAndLines[0];
			currentIndex = 1;
			linesInHunk = fileAndLines[1].split(',');
			fileLineMap = new Map();
		} else {
			//lines from next hunk
			linesInHunk = fileAndLines[0].split(',');
			fileLineMap = fileToLineMaps.get(currentFileName);
		}

		linesInHunk.forEach((lineNumber) => {
			let lineNumberInteger = parseInt(lineNumber);
			fileLineMap.set(lineNumberInteger, currentIndex++);
		});
		fileToLineMaps.set(currentFileName, fileLineMap);
	});

	return fileToLineMaps;
}

function filterAndTranslatePositionReviewComments(allComments, positionMaps) {
	let relevantComments = [];

	allComments.forEach((comment) => {
		let line = comment.position;
		let filename = comment.path;
		if (!positionMaps.has(filename)) {
			console.warn(`${filename} not in git diff`);
			return;
		}
		let lineToPosition = positionMaps.get(filename);
		if (!lineToPosition.has(line)) {
			console.warn(`line ${line} is not in git diff for ${filename}`);
			return;
		}
		comment.position = lineToPosition.get(line);
		relevantComments.push(comment);
	});
	return relevantComments;
}

let lineMaps = getLineToPositionMaps(lineDiffData);
let relevantComments = filterAndTranslatePositionReviewComments(comments, lineMaps);

fs.writeFileSync(commentsPath, JSON.stringify(relevantComments));
