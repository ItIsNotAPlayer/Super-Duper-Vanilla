// Completely disable this program (I won't be using this anytime soon)
#ifdef VERTEX
    void main(){
        gl_Position = vec4(0);
    }
#endif

#ifdef FRAGMENT
    void main(){
        discard;
    }
#endif