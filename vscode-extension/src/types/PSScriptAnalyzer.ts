export interface position {
    Column: number;
    Line: number;
}

export interface SuggestedCorrection {
    Description: string;
    End: position;
    EndColumnNumber: number;
    EndLineNumber: number;
    File: string;
    Lines: string[];
    Start: position;
    StartColumnNumber: number;
    StartLineNumber: number;
    Text: string;
}
