declare module 'node-powershell' {
    class shell {
        constructor(options: ShellOptions);
        public addCommand(command: string): void;
        public invoke(): Promise<string>;
        public dispose(): Promise<void>;
        public invocationStateInfo: string;
        public pid: number;
    }
    interface ShellOptions {
        executionPolicy: string;
        noProfile: boolean;
    }
    export = shell;
}

