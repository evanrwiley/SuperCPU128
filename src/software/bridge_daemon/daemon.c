#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
#include <time.h>

// HPS-to-FPGA Bridge Base Address (Must match Quartus)
#define BRIDGE_BASE 0xFF200000
#define BRIDGE_SPAN 0x1000

// Register Offsets (Must match debug_bridge.v and ide_main.asm)
#define REG_CMD_TYPE  0x00 // 0=Idle, 0x10=Build, 0x20=Sprite, 0x30=SID
#define REG_CMD_ADDR  0x04
#define REG_CMD_DATA  0x08
#define REG_CMD_VALID 0x10 // 1 = C64 has sent a command
#define REG_CMD_DONE  0x14 // 1 = ARM has finished processing

// Command Codes
#define CMD_BUILD  0x10
#define CMD_SPRITE 0x20
#define CMD_SID    0x30
#define CMD_AI_CFG 0x40

void *bridge_map;
volatile uint32_t *bridge_regs;

void run_python_tool(const char *cmd) {
    printf("[Daemon] Running: %s\n", cmd);
    int status = system(cmd);
    if (status != 0) {
        printf("[Daemon] Error: Command failed with status %d\n", status);
    }
}

void handle_command(uint32_t cmd_type) {
    char sys_cmd[512];
    
    switch (cmd_type) {
        case CMD_SPRITE:
            // Example: C64 requested a sprite. 
            // In a real implementation, we'd read the "Prompt" from shared RAM.
            // For now, we'll just run a demo.
            sprintf(sys_cmd, "python3 ../creator_cli.py sprite --generate \"Random Sprite\" --output /tmp/sprite.bin --format bin");
            run_python_tool(sys_cmd);
            // TODO: Inject /tmp/sprite.bin back to C64 memory
            break;

        case CMD_SID:
            sprintf(sys_cmd, "python3 ../creator_cli.py sid --compose \"Demo Sound\" --output /tmp/sound.asm");
            run_python_tool(sys_cmd);
            break;

        case CMD_BUILD:
            // C64 requested a build of the current project
            sprintf(sys_cmd, "python3 ../creator_cli.py build --source project.asm --inject");
            run_python_tool(sys_cmd);
            break;
            
        case CMD_AI_CFG:
             sprintf(sys_cmd, "python3 ../ai_service/config_tool.py --list");
             run_python_tool(sys_cmd);
             break;

        default:
            printf("[Daemon] Unknown command: 0x%02X\n", cmd_type);
    }
}

int main() {
    int fd;

    printf("[Daemon] Starting SuperCPU Bridge Daemon...\n");

    // Open /dev/mem
    if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        perror("open");
        return 1;
    }

    // Map the bridge
    bridge_map = mmap(NULL, BRIDGE_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, BRIDGE_BASE);
    if (bridge_map == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    bridge_regs = (volatile uint32_t *)bridge_map;

    printf("[Daemon] Bridge mapped. Listening for C64 commands...\n");

    while (1) {
        // Poll for Valid bit
        uint32_t valid = bridge_regs[REG_CMD_VALID / 4];
        
        if (valid) {
            uint32_t cmd_type = bridge_regs[REG_CMD_TYPE / 4];
            printf("[Daemon] Received Command: 0x%02X\n", cmd_type);
            
            // Process
            handle_command(cmd_type);
            
            // Acknowledge
            bridge_regs[REG_CMD_DONE / 4] = 1;
            
            // Wait for C64 to clear Valid
            while (bridge_regs[REG_CMD_VALID / 4]);
            
            // Clear Done
            bridge_regs[REG_CMD_DONE / 4] = 0;
        }
        
        usleep(10000); // 10ms sleep to save CPU
    }

    return 0;
}
