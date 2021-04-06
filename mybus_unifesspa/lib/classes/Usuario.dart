class Usuario{
  String nome;
  String email;
  String senha;
  String cidade;
  int q1;
  int q2;
  int q3;
  int q4;

  Usuario(this.nome, this.email, this.senha, this.cidade, this.q1, this.q2, this.q3, this.q4);

  Map<String, dynamic> toMap(){
    return {
      "nome":this.nome,
      "email":this.email,
      "cidade":this.cidade,
      "Q1":this.q1,
      "Q2":this.q2,
      "Q3":this.q3,
      "Q4":this.q4,
    };
  }
}