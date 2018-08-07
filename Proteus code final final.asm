#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here
         jmp    t_isr

;data
          temp dw 0
          pres dw 0
          humi dw 0
          cnt1 db 0
          temp1 db 0
          temp2 db 0
          pres1 db 0
          pres2 db 0
          humi1 db 0
          humi2 db 0
          nega db 10000b
          db     1007 dup(0)

;main program from 400h
          
          cli 
; intialize ds, es,ss to start of RAM
          mov       ax,0200h
          mov       ds,ax
          mov       es,ax
          mov       ss,ax
          mov       sp,0FFFEH

;initialise 8255a
          mov al,10000000b     
          out 06H, al

;initialise 8255b
          mov al,10010010b     
          out 0EH, al

;initialise 8253 and load count
          mov al,00010110b
          out 16H , al
          mov al,2
          out 10H , al

          mov al,01110100b
          out 16H , al
          mov ax,10000d
          out 12H , al
          mov al, ah
          out 12H , al

          mov al,10110100b
          out 16H ,al  
          mov ax, 30000d        
          out 14H ,al
          mov al, ah
          out 14H , al

;initialise 8259
          mov al,00010011b
          out 18h,al
          mov al,40h
          out 1Ah,al
          mov al,00000011b
          out 1Ah,al
          mov al,11111110b
          out 1Ah,al
sti

;delay for warmup

;read once and update display
call read
call updt

;display loop forever
x1:       in al,0Ah                ;polling for switch press
          and al,1
          cmp al,1
          jnz x20
          call updt
x20:      mov al,0111b
          add al,nega
          out 04h,al
          mov al,temp1
          and al,0Fh
          mov cl,4
          rol al,cl
          mov bl,pres1
          and bl,0F0h
          mov cl,4
          rol bl,cl
          add al,bl
          out 00h,al
          mov al,humi1
          and al,0Fh
          out 02h,al

          mov al,1011b
          add al,nega
          out 04h,al
          mov al,temp2
          and al,0F0h
          mov bl,pres1
          and bl,0Fh
          add al,bl
          out 00h,al
          mov al,humi2
          and al,0F0h
          mov cl,4
          rol al,cl
          out 02h,al

          mov al,1101b
          add al,nega
          out 04h,al
          mov al,temp2
          and al,0Fh
          mov cl,4
          rol al,cl
          mov bl,pres2
          and bl,0F0h
          mov cl,4
          rol bl,cl
          add al,bl
          out 00h,al
          mov al,humi2
          and al,0Fh
          out 02h,al

          mov al,1110b
          add al,nega
          out 04h,al
          mov al,pres2
          and al,0Fh
          out 00h,al

          jmp       x1

;isr every 5 min
t_isr:    call read

          inc byte ptr cnt1
          mov al,12
          cmp cnt1,al
          jnz aa
          mov al,0
          mov cnt1,al
          call updt

aa:       iret
          
read proc near
          mov ah,0
          ;temperature
          mov al,00h
          out 0Ch,al
          mov al,10h
          out 0Ch,al
          mov al,08h
          out 0Ch,al
          mov al,00h
          out 0Ch,al

x26:      in al,0Ah
          and al,10b
          cmp al,0
          jnz x26

x27:      in al,0Ah
          and al,10b
          cmp al,0
          jz x27

          mov al,01h
          out 0Ch,al
          mov al,00100001b
          out 0Ch,al
          mov al,01h
          out 0Ch,al

          in al,08h
          add temp,ax

          ;pressure
          mov al,01h
          out 0Ch,al
          mov al,11h
          out 0Ch,al
          mov al,09h
          out 0Ch,al
          mov al,01h
          out 0Ch,al

x24:      in al,0Ah
          and al,10b
          cmp al,0
          jnz x24

x25:      in al,0Ah
          and al,10b
          cmp al,0
          jz x24

          mov al,01h
          out 0Ch,al
          mov al,00100001b
          out 0Ch,al
          mov al,01h
          out 0Ch,al

          in al,08h
          add pres,ax

          ;humidity
          mov al,02h
          out 0Ch,al
          mov al,12h
          out 0Ch,al
          mov al,0Ah
          out 0Ch,al
          mov al,02h
          out 0Ch,al

x22:      in al,0Ah
          and al,10b
          cmp al,0
          jnz x22

x23:      in al,0Ah
          and al,10b
          cmp al,0
          jz x23

          mov al,02h
          out 0Ch,al
          mov al,00100010b
          out 0Ch,al
          mov al,02h
          out 0Ch,al

          in al,08h
          add humi,ax
          
          ret
read endp

updt proc near
          ;temperature
          mov ax,temp
          mov dl,cnt1
          div dl
          cmp al,128
          jae bb
          mov bl,0
          mov nega,bl
          sub al,127
          neg al
          add al,127         
bb:       mov bl,10000b
          mov nega,bl
          mov cl,100
          mul cl
          mov cl,0FFh
          div cl
          sub al,50
          mov dl,al
          mov al,ah           ;remainder -> al, rest -> dl
          mov ah,0
          mov cl,10
          mul cl
          mov cl,0FFh
          div cl              
          mov temp2,al
          mov al,dl
          mov ah,0
          mov cl,10
          div cl
          mov cl,4
          rol ah,cl
          add temp2,ah
          mov temp1,al

          ;pressure
          mov ax,pres
          mov dl,cnt1
          div dl
          mov cl,150
          mul cl
          mov cl,0FFh
          div cl
          mov cl,2
          mul cl
          add ax,800
          mov dx,ax
          mov cl,100
          div cl
          mov ah,0
          mov cl,10
          div cl
          mov cl,4
          rol al,cl
          mov pres1,al
          rol al,cl
          mov cl,10
          mul cl
          mov cl,100
          mul cl
          sub dx,ax
          mov ax,dx
          mov cl,100
          div cl
          add pres1,al
          mov ah,0
          mov cl,100
          mul cl
          sub dx,ax
          mov ax,dx
          mov cl,10
          div cl
          mov cl,4
          rol al,cl
          mov pres2,al
          add pres2,ah

          ;humidity
          mov ax,humi
          mov dl,cnt1
          div dl
          mov cl,100
          mul cl
          mov cl,0FFh
          div cl
          mov dl,al
          mov al,ah           ;remainder -> al, rest -> dl
          mov ah,0
          mov cl,10
          mul cl
          mov cl,0FFh
          div cl              
          mov humi2,al
          mov al,dl
          mov ah,0
          mov cl,10
          div cl
          mov cl,4
          rol ah,cl
          add humi2,ah
          mov humi1,al
          mov al, humi2
          and al, 0Fh
          mov dl, 5
          cmp al, dl
          jl X5
          mov al, 5
          jmp X6
      X5: mov al, 0
      X6: mov dl, humi2
          and dl, 0F0h
          mov humi2, dl
          add humi2, al

          ret
updt endp
